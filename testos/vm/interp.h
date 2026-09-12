/*
 * interp.h — интерпретатор байткода поверх classfile.h.
 *
 * Поддерживает int-арифметику, ветвления/циклы, вызов методов внутри одного
 * класса и два "нативных" класса: Native (println/print — отладочный вывод)
 * и UI (label/button/setText/remove/pollEvent/sleepMs — мост к реальному
 * интерфейсу). Обе группы методов реализованы не здесь, а в native_host.h —
 * см. его комментарий про host_*() и подмену реализации под Linux/iOS.
 */
#ifndef TESTOS_INTERP_H
#define TESTOS_INTERP_H

#include "classfile.h"

/* Выполняет статический метод с заданным именем+дескриптором (аргументов
 * пока не передаём — не нужно для M1: main() всегда "()V"/"([Ljava/lang/String;)V").
 * Возвращает 0 при успехе, -1 при ошибке рантайма (печатает причину в stderr). */
int interp_run_static(class_file_t *cf, const char *method_name, const char *descriptor);

#endif
