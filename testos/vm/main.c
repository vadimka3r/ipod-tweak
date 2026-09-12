/* main.c — тестовый харнесс: загрузить .class и выполнить его main(). */
#include <stdio.h>
#include "classfile.h"
#include "interp.h"

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <ClassFile.class>\n", argv[0]);
        return 1;
    }
    class_file_t *cf = classfile_load(argv[1]);
    if (!cf) return 1;

    fprintf(stderr, "[vm] загружен класс %s (extends %s), методов: %u\n",
            cf->this_class_name, cf->super_class_name, cf->methods_count);

    int rc = interp_run_static(cf, "main", "([Ljava/lang/String;)V");
    classfile_free(cf);
    return rc == 0 ? 0 : 1;
}
