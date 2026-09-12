/*
 * native_uikit.mm — реализация native_host.h для реального iPod: те же
 * функции, что native_console.c на Linux, но здесь они реально создают
 * UIKit-виджеты. Собирается вместе с swipeuplock (Objective-C++ файл в
 * Theos-проекте твика), линкуется с classfile.c/interp.c/native_uikit.mm
 * (БЕЗ native_console.c — они реализуют одни и те же host_*() функции,
 * линковать оба нельзя, будет конфликт символов).
 *
 * Важно про потоки: сама VM (interp_run_static) крутится в фоновом потоке
 * (см. testos_vm_start в этом же файле, вызывается из Tweak.xm). UIKit
 * можно трогать только с главного потока — поэтому каждый host_ui_*
 * вызов оборачивается в dispatch_sync на main queue. dispatch_sync, а не
 * dispatch_async — потому что Java-код должен видеть эффект вызова сразу
 * (например, pollEvent() после button() должен уже видеть кнопку в
 * иерархии view).
 */
#import <UIKit/UIKit.h>
#include <pthread.h>
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include "../vm/native_host.h"
#include "../vm/classfile.h"
#include "../vm/interp.h"

/* Контейнер, в который добавляются все UI.*-виджеты. Устанавливается из
 * Tweak.xm при старте (это и есть то самое полноэкранное окно поверх
 * SpringBoard, которое мы уже сделали в testOS boot-block). */
static UIView *g_root_view = nil;

/* handle -> UIView*, простым линейным массивом — виджетов у нас будет
 * немного (рабочий стол + пара окон приложений), не нужна хэш-таблица. */
#define MAX_WIDGETS 64
typedef struct { int handle; UIView *view; int is_button; } widget_t;
static widget_t g_widgets[MAX_WIDGETS];
static int g_widget_count = 0;

/* Очередь событий тапов: main thread (обработчик кнопки) кладёт handle,
 * поток VM его забирает через host_ui_poll_event(). Один общий мьютекс —
 * событий мало и редко, простая блокировка более чем достаточна. */
#define EVENT_QUEUE_SIZE 16
static int g_event_queue[EVENT_QUEUE_SIZE];
static int g_event_head = 0, g_event_tail = 0;
static pthread_mutex_t g_event_mutex = PTHREAD_MUTEX_INITIALIZER;

static void push_event(int handle) {
    pthread_mutex_lock(&g_event_mutex);
    int next = (g_event_tail + 1) % EVENT_QUEUE_SIZE;
    if (next != g_event_head) { /* не переполняем, лишний тап молча теряем */
        g_event_queue[g_event_tail] = handle;
        g_event_tail = next;
    }
    pthread_mutex_unlock(&g_event_mutex);
}

static int pop_event(void) {
    int result = -1;
    pthread_mutex_lock(&g_event_mutex);
    if (g_event_head != g_event_tail) {
        result = g_event_queue[g_event_head];
        g_event_head = (g_event_head + 1) % EVENT_QUEUE_SIZE;
    }
    pthread_mutex_unlock(&g_event_mutex);
    return result;
}

static UIView *find_widget(int handle) {
    for (int i = 0; i < g_widget_count; i++) {
        if (g_widgets[i].handle == handle) return g_widgets[i].view;
    }
    return nil;
}

/* Обработчик тапа по нашим кнопкам. tag на UIButton = handle (int),
 * дешёвый способ не заводить отдельный NSDictionary handle->target. */
@interface TestOSButtonTarget : NSObject
+ (void)buttonTapped:(UIButton *)sender;
@end
@implementation TestOSButtonTarget
+ (void)buttonTapped:(UIButton *)sender {
    push_event((int)sender.tag);
}
@end

extern "C" {

void testos_uikit_set_root_view(UIView *root) {
    g_root_view = root;
}

void host_println_int(int value) {
    NSLog(@"[testos] %d", value);
}
void host_println_str(const char *s) {
    NSLog(@"[testos] %s", s ? s : "(null)");
}
void host_print_str(const char *s) {
    NSLog(@"[testos] %s", s ? s : "(null)");
}

void host_ui_label(int handle, int x, int y, int w, int h, const char *text) {
    NSString *nstext = [NSString stringWithUTF8String:text ? text : ""];
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIView *existing = find_widget(handle);
        if (existing && [existing isKindOfClass:[UILabel class]]) {
            ((UILabel *)existing).text = nstext;
            existing.frame = CGRectMake(x, y, w, h);
            return;
        }
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, h)];
        label.text = nstext;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        [g_root_view addSubview:label];
        if (g_widget_count < MAX_WIDGETS) {
            g_widgets[g_widget_count].handle = handle;
            g_widgets[g_widget_count].view = label;
            g_widgets[g_widget_count].is_button = 0;
            g_widget_count++;
        }
    });
}

void host_ui_button(int handle, int x, int y, int w, int h, const char *text) {
    NSString *nstext = [NSString stringWithUTF8String:text ? text : ""];
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIView *existing = find_widget(handle);
        if (existing && [existing isKindOfClass:[UIButton class]]) {
            [(UIButton *)existing setTitle:nstext forState:UIControlStateNormal];
            existing.frame = CGRectMake(x, y, w, h);
            return;
        }
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(x, y, w, h);
        [button setTitle:nstext forState:UIControlStateNormal];
        button.tag = handle;
        [button addTarget:[TestOSButtonTarget class]
                    action:@selector(buttonTapped:)
          forControlEvents:UIControlEventTouchUpInside];
        [g_root_view addSubview:button];
        if (g_widget_count < MAX_WIDGETS) {
            g_widgets[g_widget_count].handle = handle;
            g_widgets[g_widget_count].view = button;
            g_widgets[g_widget_count].is_button = 1;
            g_widget_count++;
        }
    });
}

void host_ui_set_text(int handle, const char *text) {
    NSString *nstext = [NSString stringWithUTF8String:text ? text : ""];
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIView *v = find_widget(handle);
        if (!v) return;
        if ([v isKindOfClass:[UILabel class]]) ((UILabel *)v).text = nstext;
        else if ([v isKindOfClass:[UIButton class]]) [(UIButton *)v setTitle:nstext forState:UIControlStateNormal];
    });
}

void host_ui_remove(int handle) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (int i = 0; i < g_widget_count; i++) {
            if (g_widgets[i].handle == handle) {
                [g_widgets[i].view removeFromSuperview];
                g_widgets[i] = g_widgets[g_widget_count - 1];
                g_widget_count--;
                return;
            }
        }
    });
}

int host_ui_poll_event(void) {
    return pop_event();
}

void host_sleep_ms(int ms) {
    struct timespec ts;
    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (long)(ms % 1000) * 1000000L;
    nanosleep(&ts, NULL);
}

} /* extern "C" */

/* --- Запуск VM в фоновом потоке --- */

typedef struct {
    char class_path[1024];
} vm_thread_args_t;

static void *vm_thread_main(void *arg) {
    vm_thread_args_t *args = (vm_thread_args_t *)arg;
    class_file_t *cf = classfile_load(args->class_path);
    if (!cf) {
        NSLog(@"[testos] не удалось загрузить %s", args->class_path);
        free(args);
        return NULL;
    }
    NSLog(@"[testos] запускаю %s.main()", cf->this_class_name);
    interp_run_static(cf, "main", "([Ljava/lang/String;)V");
    NSLog(@"[testos] %s.main() завершился", cf->this_class_name);
    classfile_free(cf);
    free(args);
    return NULL;
}

/* Вызывается из Tweak.xm после того как g_root_view уже установлен. Путь —
 * абсолютный путь на файловой системе айпода к .class-файлу (например,
 * /Library/TestOS/Desktop.class), в который мы вручную кладём собранные
 * Java-программы вместе с установкой твика (см. control/Makefile). */
extern "C" void testos_vm_start(const char *class_path) {
    vm_thread_args_t *args = (vm_thread_args_t *)malloc(sizeof(vm_thread_args_t));
    strncpy(args->class_path, class_path, sizeof(args->class_path) - 1);
    args->class_path[sizeof(args->class_path) - 1] = '\0';

    pthread_t thread;
    pthread_create(&thread, NULL, vm_thread_main, args);
    pthread_detach(thread);
}
