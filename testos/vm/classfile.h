/*
 * classfile.h — минимальный парсер формата .class (JVM Spec, версии до Java 8
 * достаточно, целимся на javac -target 8 -source 8, чтобы constant pool не
 * содержал новых записей вроде InvokeDynamic/MethodHandle, которые нам не
 * нужны и не поддерживаются).
 */
#ifndef TESTOS_CLASSFILE_H
#define TESTOS_CLASSFILE_H

#include <stdint.h>
#include <stddef.h>

typedef enum {
    CP_UTF8 = 1,
    CP_INTEGER = 3,
    CP_FLOAT = 4,
    CP_LONG = 5,
    CP_DOUBLE = 6,
    CP_CLASS = 7,
    CP_STRING = 8,
    CP_FIELDREF = 9,
    CP_METHODREF = 10,
    CP_INTERFACE_METHODREF = 11,
    CP_NAME_AND_TYPE = 12,
} cp_tag_t;

typedef struct {
    uint8_t tag;
    union {
        struct { char *bytes; uint16_t len; } utf8;
        int32_t integer;
        float flt;
        int64_t long_;
        double dbl;
        struct { uint16_t name_index; } class_;
        struct { uint16_t string_index; } string;
        struct { uint16_t class_index; uint16_t name_and_type_index; } ref;
        struct { uint16_t name_index; uint16_t descriptor_index; } name_and_type;
    } u;
} cp_info_t;

typedef struct {
    char *name;
    uint32_t code_length;
    uint8_t *code;
    uint16_t max_stack;
    uint16_t max_locals;
} code_attr_t;

typedef struct {
    uint16_t access_flags;
    char *name;
    char *descriptor;
    int has_code;
    code_attr_t code;
} method_info_t;

typedef struct {
    char *name;
    char *descriptor;
    uint16_t access_flags;
    int has_constant_value;
    int32_t constant_value_int; /* хватает для наших static final int */
} field_info_t;

typedef struct {
    uint16_t constant_pool_count;
    cp_info_t *constant_pool; /* индексация с 1, слот [0] не используется */

    uint16_t access_flags;
    char *this_class_name;
    char *super_class_name;

    uint16_t fields_count;
    field_info_t *fields;

    uint16_t methods_count;
    method_info_t *methods;
} class_file_t;

/* Загружает и парсит .class из файла. Возвращает NULL при ошибке (печатает
 * причину в stderr). Освобождать через classfile_free(). */
class_file_t *classfile_load(const char *path);
void classfile_free(class_file_t *cf);

/* Вспомогательные функции доступа к constant pool. */
const char *cf_utf8(const class_file_t *cf, uint16_t index);
const char *cf_class_name(const class_file_t *cf, uint16_t class_index);

/* Найти метод по имени+дескриптору (NULL если нет). */
method_info_t *cf_find_method(const class_file_t *cf, const char *name, const char *descriptor);

#endif
