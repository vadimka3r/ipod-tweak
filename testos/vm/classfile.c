#define _POSIX_C_SOURCE 200809L
#include "classfile.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* --- Простой байтовый ридер с big-endian форматом .class --- */
typedef struct {
    const uint8_t *data;
    size_t len;
    size_t pos;
    int error;
} reader_t;

static uint8_t r_u1(reader_t *r) {
    if (r->pos + 1 > r->len) { r->error = 1; return 0; }
    return r->data[r->pos++];
}
static uint16_t r_u2(reader_t *r) {
    uint16_t hi = r_u1(r), lo = r_u1(r);
    return (uint16_t)((hi << 8) | lo);
}
static uint32_t r_u4(reader_t *r) {
    uint32_t a = r_u1(r), b = r_u1(r), c = r_u1(r), d = r_u1(r);
    return (a << 24) | (b << 16) | (c << 8) | d;
}
static const uint8_t *r_bytes(reader_t *r, size_t n) {
    if (r->pos + n > r->len) { r->error = 1; return NULL; }
    const uint8_t *p = r->data + r->pos;
    r->pos += n;
    return p;
}
static void r_skip(reader_t *r, size_t n) { r_bytes(r, n); }

static int parse_constant_pool(reader_t *r, class_file_t *cf) {
    cf->constant_pool = calloc(cf->constant_pool_count, sizeof(cp_info_t));
    /* индекс 0 не используется JVM-спекой; идём с 1 */
    for (uint16_t i = 1; i < cf->constant_pool_count; i++) {
        uint8_t tag = r_u1(r);
        cf->constant_pool[i].tag = tag;
        switch (tag) {
            case CP_UTF8: {
                uint16_t len = r_u2(r);
                const uint8_t *bytes = r_bytes(r, len);
                if (!bytes) return 0;
                char *s = malloc(len + 1);
                memcpy(s, bytes, len);
                s[len] = '\0';
                cf->constant_pool[i].u.utf8.bytes = s;
                cf->constant_pool[i].u.utf8.len = len;
                break;
            }
            case CP_INTEGER:
                cf->constant_pool[i].u.integer = (int32_t)r_u4(r);
                break;
            case CP_FLOAT: {
                uint32_t bits = r_u4(r);
                float f; memcpy(&f, &bits, 4);
                cf->constant_pool[i].u.flt = f;
                break;
            }
            case CP_LONG: {
                uint32_t hi = r_u4(r), lo = r_u4(r);
                cf->constant_pool[i].u.long_ = ((int64_t)hi << 32) | lo;
                i++; /* long/double занимают два слота в constant pool */
                break;
            }
            case CP_DOUBLE: {
                uint32_t hi = r_u4(r), lo = r_u4(r);
                uint64_t bits = ((uint64_t)hi << 32) | lo;
                double d; memcpy(&d, &bits, 8);
                cf->constant_pool[i].u.dbl = d;
                i++;
                break;
            }
            case CP_CLASS:
                cf->constant_pool[i].u.class_.name_index = r_u2(r);
                break;
            case CP_STRING:
                cf->constant_pool[i].u.string.string_index = r_u2(r);
                break;
            case CP_FIELDREF:
            case CP_METHODREF:
            case CP_INTERFACE_METHODREF:
                cf->constant_pool[i].u.ref.class_index = r_u2(r);
                cf->constant_pool[i].u.ref.name_and_type_index = r_u2(r);
                break;
            case CP_NAME_AND_TYPE:
                cf->constant_pool[i].u.name_and_type.name_index = r_u2(r);
                cf->constant_pool[i].u.name_and_type.descriptor_index = r_u2(r);
                break;
            default:
                fprintf(stderr, "classfile: неподдерживаемый tag=%d в constant pool "
                                "(нужен javac -target 8, без invokedynamic/lambda)\n", tag);
                return 0;
        }
        if (r->error) return 0;
    }
    return 1;
}

const char *cf_utf8(const class_file_t *cf, uint16_t index) {
    if (index == 0 || index >= cf->constant_pool_count) return NULL;
    if (cf->constant_pool[index].tag != CP_UTF8) return NULL;
    return cf->constant_pool[index].u.utf8.bytes;
}

const char *cf_class_name(const class_file_t *cf, uint16_t class_index) {
    if (class_index == 0 || class_index >= cf->constant_pool_count) return NULL;
    if (cf->constant_pool[class_index].tag != CP_CLASS) return NULL;
    return cf_utf8(cf, cf->constant_pool[class_index].u.class_.name_index);
}

/* Пропускает произвольный attribute (мы не знаем/не используем его),
 * либо разбирает Code, если это он. */
static int parse_attributes_for_method(reader_t *r, class_file_t *cf, method_info_t *m) {
    uint16_t count = r_u2(r);
    for (uint16_t i = 0; i < count; i++) {
        uint16_t name_index = r_u2(r);
        uint32_t length = r_u4(r);
        const char *aname = cf_utf8(cf, name_index);
        if (aname && strcmp(aname, "Code") == 0) {
            m->has_code = 1;
            m->code.max_stack = r_u2(r);
            m->code.max_locals = r_u2(r);
            m->code.code_length = r_u4(r);
            const uint8_t *code_bytes = r_bytes(r, m->code.code_length);
            if (!code_bytes) return 0;
            m->code.code = malloc(m->code.code_length);
            memcpy(m->code.code, code_bytes, m->code.code_length);

            /* exception table */
            uint16_t exc_count = r_u2(r);
            r_skip(r, exc_count * 8u);

            /* вложенные атрибуты Code (LineNumberTable и т.п.) — пропускаем */
            uint16_t sub_count = r_u2(r);
            for (uint16_t j = 0; j < sub_count; j++) {
                r_u2(r); /* name index */
                uint32_t sub_len = r_u4(r);
                r_skip(r, sub_len);
            }
        } else {
            r_skip(r, length);
        }
        if (r->error) return 0;
    }
    return 1;
}

static int skip_generic_attributes(reader_t *r) {
    uint16_t count = r_u2(r);
    for (uint16_t i = 0; i < count; i++) {
        r_u2(r); /* name index */
        uint32_t length = r_u4(r);
        r_skip(r, length);
        if (r->error) return 0;
    }
    return 1;
}

class_file_t *classfile_load(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "classfile: не могу открыть %s\n", path); return NULL; }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *buf = malloc((size_t)size);
    if (fread(buf, 1, (size_t)size, f) != (size_t)size) {
        fprintf(stderr, "classfile: ошибка чтения %s\n", path);
        fclose(f); free(buf); return NULL;
    }
    fclose(f);

    reader_t r = { buf, (size_t)size, 0, 0 };
    class_file_t *cf = calloc(1, sizeof(class_file_t));

    uint32_t magic = r_u4(&r);
    if (magic != 0xCAFEBABEu) {
        fprintf(stderr, "classfile: неверная магическая сигнатура (не .class файл?)\n");
        free(buf); free(cf); return NULL;
    }
    r_u2(&r); /* minor version */
    uint16_t major = r_u2(&r);
    if (major > 52) {
        fprintf(stderr, "classfile: версия class-файла %u слишком новая — "
                        "компилируйте с javac -source 8 -target 8\n", major);
    }

    cf->constant_pool_count = r_u2(&r);
    if (!parse_constant_pool(&r, cf)) goto fail;

    cf->access_flags = r_u2(&r);
    uint16_t this_class = r_u2(&r);
    uint16_t super_class = r_u2(&r);
    cf->this_class_name = strdup(cf_class_name(cf, this_class) ? cf_class_name(cf, this_class) : "?");
    const char *super_name = super_class ? cf_class_name(cf, super_class) : NULL;
    cf->super_class_name = strdup(super_name ? super_name : "");

    uint16_t interfaces_count = r_u2(&r);
    r_skip(&r, interfaces_count * 2u);

    cf->fields_count = r_u2(&r);
    cf->fields = calloc(cf->fields_count, sizeof(field_info_t));
    for (uint16_t i = 0; i < cf->fields_count; i++) {
        field_info_t *fld = &cf->fields[i];
        fld->access_flags = r_u2(&r);
        uint16_t name_index = r_u2(&r);
        uint16_t desc_index = r_u2(&r);
        fld->name = strdup(cf_utf8(cf, name_index));
        fld->descriptor = strdup(cf_utf8(cf, desc_index));
        uint16_t attr_count = r_u2(&r);
        for (uint16_t j = 0; j < attr_count; j++) {
            uint16_t aname_idx = r_u2(&r);
            uint32_t alen = r_u4(&r);
            const char *aname = cf_utf8(cf, aname_idx);
            if (aname && strcmp(aname, "ConstantValue") == 0 && alen == 2) {
                uint16_t cv_index = r_u2(&r);
                if (cf->constant_pool[cv_index].tag == CP_INTEGER) {
                    fld->has_constant_value = 1;
                    fld->constant_value_int = cf->constant_pool[cv_index].u.integer;
                }
            } else {
                r_skip(&r, alen);
            }
        }
        if (r.error) goto fail;
    }

    cf->methods_count = r_u2(&r);
    cf->methods = calloc(cf->methods_count, sizeof(method_info_t));
    for (uint16_t i = 0; i < cf->methods_count; i++) {
        method_info_t *m = &cf->methods[i];
        m->access_flags = r_u2(&r);
        uint16_t name_index = r_u2(&r);
        uint16_t desc_index = r_u2(&r);
        m->name = strdup(cf_utf8(cf, name_index));
        m->descriptor = strdup(cf_utf8(cf, desc_index));
        if (!parse_attributes_for_method(&r, cf, m)) goto fail;
        if (r.error) goto fail;
    }

    if (!skip_generic_attributes(&r)) goto fail;

    free(buf);
    return cf;

fail:
    fprintf(stderr, "classfile: ошибка парсинга %s (файл повреждён или использует "
                    "неподдерживаемые фичи байткода)\n", path);
    free(buf);
    classfile_free(cf);
    return NULL;
}

method_info_t *cf_find_method(const class_file_t *cf, const char *name, const char *descriptor) {
    for (uint16_t i = 0; i < cf->methods_count; i++) {
        if (strcmp(cf->methods[i].name, name) == 0 &&
            (descriptor == NULL || strcmp(cf->methods[i].descriptor, descriptor) == 0)) {
            return &cf->methods[i];
        }
    }
    return NULL;
}

void classfile_free(class_file_t *cf) {
    if (!cf) return;
    if (cf->constant_pool) {
        for (uint16_t i = 1; i < cf->constant_pool_count; i++) {
            if (cf->constant_pool[i].tag == CP_UTF8) free(cf->constant_pool[i].u.utf8.bytes);
        }
        free(cf->constant_pool);
    }
    free(cf->this_class_name);
    free(cf->super_class_name);
    for (uint16_t i = 0; i < cf->fields_count; i++) {
        free(cf->fields[i].name);
        free(cf->fields[i].descriptor);
    }
    free(cf->fields);
    for (uint16_t i = 0; i < cf->methods_count; i++) {
        free(cf->methods[i].name);
        free(cf->methods[i].descriptor);
        free(cf->methods[i].code.code);
    }
    free(cf->methods);
    free(cf);
}
