#include "interp.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* Слот стека/локалов. Для M1 хватает 64-битного слова: int кладём как
 * есть, указатель на C-строку (для String-констант) кладём приведённым к
 * int64_t. Учёт типов минимальный (мы не разделяем int/ref в рантайме) —
 * это сознательное упрощение для доказательства подхода, в M2 добавим
 * нормальные объекты и тип-теги. */
typedef int64_t slot_t;

#define MAX_STACK 256
#define MAX_LOCALS 256
#define MAX_CALL_DEPTH 64

typedef struct {
    slot_t stack[MAX_STACK];
    int sp;
    slot_t locals[MAX_LOCALS];
} frame_t;

static int g_depth = 0;

static uint16_t read_u2(const uint8_t *code, int pc) {
    return (uint16_t)((code[pc] << 8) | code[pc + 1]);
}
static int16_t read_s2(const uint8_t *code, int pc) {
    return (int16_t)read_u2(code, pc);
}

/* Реализация "системных вызовов" — единственный способ Java-коду достучаться
 * до внешнего мира на этом этапе. В M4 сюда добавятся drawRect/onTouch и т.п.,
 * а на iOS они будут дёргать реальный UIKit через native-bridge. */
static int call_native(const char *method_name, const char *descriptor, frame_t *caller, int arg_count) {
    if (strcmp(method_name, "println") == 0 && strcmp(descriptor, "(I)V") == 0) {
        int v = (int)caller->stack[caller->sp - 1];
        printf("%d\n", v);
        caller->sp -= arg_count;
        return 0;
    }
    if (strcmp(method_name, "print") == 0 && strcmp(descriptor, "(Ljava/lang/String;)V") == 0) {
        const char *s = (const char *)(intptr_t)caller->stack[caller->sp - 1];
        printf("%s", s ? s : "(null)");
        caller->sp -= arg_count;
        return 0;
    }
    if (strcmp(method_name, "println") == 0 && strcmp(descriptor, "(Ljava/lang/String;)V") == 0) {
        const char *s = (const char *)(intptr_t)caller->stack[caller->sp - 1];
        printf("%s\n", s ? s : "(null)");
        caller->sp -= arg_count;
        return 0;
    }
    fprintf(stderr, "interp: неизвестный нативный метод Native.%s%s\n", method_name, descriptor);
    return -1;
}

static int count_args(const char *descriptor) {
    /* Считаем только количество параметров-слотов для примитивов/ссылок
     * одинарной ширины ((I)V, (Ljava/lang/String;)V и т.п.) — long/double
     * в M1 не поддерживаются. */
    int count = 0;
    const char *p = descriptor;
    if (*p != '(') return 0;
    p++;
    while (*p != ')') {
        if (*p == 'L') { while (*p != ';') p++; p++; }
        else p++;
        count++;
    }
    return count;
}

static int exec_method(class_file_t *cf, method_info_t *m, slot_t *args, int nargs, slot_t *ret_out) {
    if (++g_depth > MAX_CALL_DEPTH) {
        fprintf(stderr, "interp: превышена глубина вызовов (нет ли бесконечной рекурсии?)\n");
        g_depth--;
        return -1;
    }
    if (!m->has_code) {
        fprintf(stderr, "interp: метод %s%s без Code-атрибута (abstract/native не поддерживаются)\n",
                m->name, m->descriptor);
        g_depth--;
        return -1;
    }

    frame_t frame;
    frame.sp = 0;
    memset(frame.locals, 0, sizeof(frame.locals));
    for (int i = 0; i < nargs && i < MAX_LOCALS; i++) frame.locals[i] = args[i];

    const uint8_t *code = m->code.code;
    int pc = 0;
    int len = (int)m->code.code_length;

    while (pc < len) {
        uint8_t op = code[pc];
        switch (op) {
            case 0x00: /* nop */
                pc += 1; break;

            case 0x02: case 0x03: case 0x04: case 0x05: case 0x06: case 0x07: case 0x08:
                /* iconst_m1 .. iconst_5 */
                frame.stack[frame.sp++] = (int32_t)op - 0x03;
                pc += 1; break;

            case 0x10: /* bipush */
                frame.stack[frame.sp++] = (int8_t)code[pc + 1];
                pc += 2; break;

            case 0x11: /* sipush */
                frame.stack[frame.sp++] = read_s2(code, pc + 1);
                pc += 3; break;

            case 0x12: { /* ldc */
                uint8_t idx = code[pc + 1];
                cp_info_t *e = &cf->constant_pool[idx];
                if (e->tag == CP_INTEGER) {
                    frame.stack[frame.sp++] = e->u.integer;
                } else if (e->tag == CP_STRING) {
                    const char *s = cf_utf8(cf, e->u.string.string_index);
                    frame.stack[frame.sp++] = (intptr_t)s;
                } else {
                    fprintf(stderr, "interp: ldc с неподдерживаемым типом constant pool (tag=%d)\n", e->tag);
                    g_depth--; return -1;
                }
                pc += 2; break;
            }

            case 0x15: /* iload */
                frame.stack[frame.sp++] = frame.locals[code[pc + 1]];
                pc += 2; break;
            case 0x1a: case 0x1b: case 0x1c: case 0x1d: /* iload_0..3 */
                frame.stack[frame.sp++] = frame.locals[op - 0x1a];
                pc += 1; break;

            case 0x36: /* istore */
                frame.locals[code[pc + 1]] = frame.stack[--frame.sp];
                pc += 2; break;
            case 0x3b: case 0x3c: case 0x3d: case 0x3e: /* istore_0..3 */
                frame.locals[op - 0x3b] = frame.stack[--frame.sp];
                pc += 1; break;

            case 0x57: /* pop */
                frame.sp -= 1; pc += 1; break;
            case 0x59: /* dup */
                frame.stack[frame.sp] = frame.stack[frame.sp - 1];
                frame.sp += 1; pc += 1; break;

            case 0x60: /* iadd */
                frame.sp--; frame.stack[frame.sp - 1] = (int32_t)(frame.stack[frame.sp - 1] + frame.stack[frame.sp]);
                pc += 1; break;
            case 0x64: /* isub */
                frame.sp--; frame.stack[frame.sp - 1] = (int32_t)(frame.stack[frame.sp - 1] - frame.stack[frame.sp]);
                pc += 1; break;
            case 0x68: /* imul */
                frame.sp--; frame.stack[frame.sp - 1] = (int32_t)(frame.stack[frame.sp - 1] * frame.stack[frame.sp]);
                pc += 1; break;
            case 0x6c: /* idiv */
                frame.sp--;
                if (frame.stack[frame.sp] == 0) {
                    fprintf(stderr, "interp: деление на ноль\n");
                    g_depth--; return -1;
                }
                frame.stack[frame.sp - 1] = (int32_t)(frame.stack[frame.sp - 1] / frame.stack[frame.sp]);
                pc += 1; break;

            case 0x84: { /* iinc */
                uint8_t idx = code[pc + 1];
                int8_t d = (int8_t)code[pc + 2];
                frame.locals[idx] = (int32_t)(frame.locals[idx] + d);
                pc += 3; break;
            }

            case 0x99: case 0x9a: case 0x9b: case 0x9c: case 0x9d: case 0x9e: {
                /* ifeq/ifne/iflt/ifge/ifgt/ifle */
                int32_t v = (int32_t)frame.stack[--frame.sp];
                int take = 0;
                switch (op) {
                    case 0x99: take = (v == 0); break;
                    case 0x9a: take = (v != 0); break;
                    case 0x9b: take = (v < 0); break;
                    case 0x9c: take = (v >= 0); break;
                    case 0x9d: take = (v > 0); break;
                    case 0x9e: take = (v <= 0); break;
                }
                pc = take ? pc + read_s2(code, pc + 1) : pc + 3;
                break;
            }

            case 0x9f: case 0xa0: case 0xa1: case 0xa2: case 0xa3: case 0xa4: {
                /* if_icmpeq/ne/lt/ge/gt/le */
                int32_t b = (int32_t)frame.stack[--frame.sp];
                int32_t a = (int32_t)frame.stack[--frame.sp];
                int take = 0;
                switch (op) {
                    case 0x9f: take = (a == b); break;
                    case 0xa0: take = (a != b); break;
                    case 0xa1: take = (a < b); break;
                    case 0xa2: take = (a >= b); break;
                    case 0xa3: take = (a > b); break;
                    case 0xa4: take = (a <= b); break;
                }
                pc = take ? pc + read_s2(code, pc + 1) : pc + 3;
                break;
            }

            case 0xa7: /* goto */
                pc = pc + read_s2(code, pc + 1);
                break;

            case 0xac: /* ireturn */
                if (ret_out) *ret_out = frame.stack[frame.sp - 1];
                g_depth--; return 0;

            case 0xb1: /* return */
                g_depth--; return 0;

            case 0xb8: { /* invokestatic */
                uint16_t cp_idx = read_u2(code, pc + 1);
                cp_info_t *ref = &cf->constant_pool[cp_idx];
                uint16_t class_idx = ref->u.ref.class_index;
                uint16_t nt_idx = ref->u.ref.name_and_type_index;
                const char *target_class = cf_class_name(cf, class_idx);
                const char *mname = cf_utf8(cf, cf->constant_pool[nt_idx].u.name_and_type.name_index);
                const char *mdesc = cf_utf8(cf, cf->constant_pool[nt_idx].u.name_and_type.descriptor_index);
                int nargs_call = count_args(mdesc);

                if (target_class && strcmp(target_class, "Native") == 0) {
                    if (call_native(mname, mdesc, &frame, nargs_call) != 0) {
                        g_depth--; return -1;
                    }
                } else if (target_class && strcmp(target_class, cf->this_class_name) == 0) {
                    method_info_t *callee = cf_find_method(cf, mname, mdesc);
                    if (!callee) {
                        fprintf(stderr, "interp: метод %s%s не найден в %s\n", mname, mdesc, target_class);
                        g_depth--; return -1;
                    }
                    slot_t call_args[MAX_LOCALS];
                    for (int i = 0; i < nargs_call; i++) call_args[i] = frame.stack[frame.sp - nargs_call + i];
                    frame.sp -= nargs_call;
                    slot_t ret = 0;
                    if (exec_method(cf, callee, call_args, nargs_call, &ret) != 0) {
                        g_depth--; return -1;
                    }
                    if (mdesc[strlen(mdesc) - 1] != 'V') frame.stack[frame.sp++] = ret;
                } else {
                    fprintf(stderr, "interp: вызов в чужой класс %s.%s%s не поддерживается в M1 "
                                    "(один класс = одна программа)\n",
                                    target_class ? target_class : "?", mname, mdesc);
                    g_depth--; return -1;
                }
                pc += 3;
                break;
            }

            default:
                fprintf(stderr, "interp: неподдерживаемый опкод 0x%02x по pc=%d в %s%s "
                                "(добавь его в interp.c, когда понадобится для реальной программы)\n",
                                op, pc, m->name, m->descriptor);
                g_depth--; return -1;
        }
    }

    g_depth--;
    return 0;
}

int interp_run_static(class_file_t *cf, const char *method_name, const char *descriptor) {
    method_info_t *m = cf_find_method(cf, method_name, descriptor);
    if (!m) {
        fprintf(stderr, "interp: точка входа %s%s не найдена в классе %s\n",
                method_name, descriptor, cf->this_class_name);
        return -1;
    }
    slot_t ret = 0;
    return exec_method(cf, m, NULL, 0, &ret);
}
