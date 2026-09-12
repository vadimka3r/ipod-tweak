/*
 * native_uikit.h — то немногое, что Tweak.xm должен знать про мост к VM.
 */
#ifndef TESTOS_NATIVE_UIKIT_H
#define TESTOS_NATIVE_UIKIT_H

#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Куда UI.label/UI.button будут добавлять свои view (наше полноэкранное
 * boot-block окно из Tweak.xm). Вызвать один раз до testos_vm_start. */
void testos_uikit_set_root_view(UIView *root);

/* Запустить VM в фоновом потоке с указанным .class как точкой входа
 * (main()). Не блокирует вызывающий поток. */
void testos_vm_start(const char *class_path);

#ifdef __cplusplus
}
#endif

#endif
