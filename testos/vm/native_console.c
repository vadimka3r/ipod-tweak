/*
 * native_console.c — реализация native_host.h для локальной разработки:
 * никакого UIKit нет, поэтому UI.* методы просто печатают, что бы они
 * сделали, в stdout. Этого достаточно, чтобы писать и проверять логику
 * Java-программ (в т.ч. будущего Desktop/утилит/игры) на Linux/в Codespace,
 * прежде чем гонять их на реальном экране айпода через native_uikit.mm.
 */
#define _POSIX_C_SOURCE 200809L
#include "native_host.h"
#include <stdio.h>
#include <time.h>

void host_println_int(int value) { printf("%d\n", value); }
void host_println_str(const char *s) { printf("%s\n", s ? s : "(null)"); }
void host_print_str(const char *s) { printf("%s", s ? s : "(null)"); }

void host_ui_label(int handle, int x, int y, int w, int h, const char *text) {
    printf("[ui] label #%d at (%d,%d) %dx%d: \"%s\"\n", handle, x, y, w, h, text ? text : "");
}
void host_ui_button(int handle, int x, int y, int w, int h, const char *text) {
    printf("[ui] button #%d at (%d,%d) %dx%d: \"%s\"\n", handle, x, y, w, h, text ? text : "");
}
void host_ui_set_text(int handle, const char *text) {
    printf("[ui] #%d setText: \"%s\"\n", handle, text ? text : "");
}
void host_ui_remove(int handle) {
    printf("[ui] #%d removed\n", handle);
}
int host_ui_poll_event(void) {
    /* На консоли тачей нет — всегда "нет события". Программы, которые ждут
     * тап в цикле, на этом хосте просто будут крутиться вхолостую — этого
     * достаточно, чтобы проверить, что они хотя бы не падают. */
    return -1;
}
void host_sleep_ms(int ms) {
    struct timespec ts;
    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (long)(ms % 1000) * 1000000L;
    nanosleep(&ts, NULL);
}
