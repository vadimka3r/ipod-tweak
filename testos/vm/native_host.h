/*
 * native_host.h — интерфейс между интерпретатором (interp.c) и конкретной
 * средой исполнения ("хостом"). Сам интерпретатор ничего не знает про
 * UIKit/printf/что угодно ещё — он просто дёргает эти функции, а их РЕАЛИЗАЦИЮ
 * подставляет хост:
 *
 *   - testos/vm/native_console.c   — для локальной разработки/теста на Linux
 *     (используется Makefile'ом в testos/vm), печатает в stdout.
 *   - testos/native-bridge/native_uikit.mm — для реального iPod: та же
 *     сигнатура функций, но внутри вызывает UIKit через dispatch_sync на
 *     главный поток (VM крутится в фоновом потоке SpringBoard).
 *
 * Смысл разделения: interp.c и classfile.c остаются переносимым кодом без
 * платформенных зависимостей, а платформенная часть — тонкий слой,
 * который легко подменить/протестировать отдельно.
 */
#ifndef TESTOS_NATIVE_HOST_H
#define TESTOS_NATIVE_HOST_H

#ifdef __cplusplus
extern "C" {
#endif

/* Native.println(int) / Native.println(String) / Native.print(String) —
 * отладочный вывод текста. На Linux — printf. На айподе — NSLog (виден
 * через `syslog`/`idevicesyslog`, полезно для отладки без экрана). */
void host_println_int(int value);
void host_println_str(const char *s);
void host_print_str(const char *s);

/* UI.label(handle, x, y, w, h, text) — создать/обновить текстовую метку.
 * handle придумывает Java-сторона (просто число), повторный вызов с тем же
 * handle обновляет существующую метку, а не создаёт новую. */
void host_ui_label(int handle, int x, int y, int w, int h, const char *text);

/* UI.button(handle, x, y, w, h, text) — создать/обновить кнопку. */
void host_ui_button(int handle, int x, int y, int w, int h, const char *text);

/* UI.setText(handle, text) — сменить текст у существующей метки/кнопки. */
void host_ui_set_text(int handle, const char *text);

/* UI.remove(handle) — убрать элемент с экрана. */
void host_ui_remove(int handle);

/* UI.pollEvent() — вернуть handle кнопки, по которой только что тапнули,
 * либо -1, если событий нет. Вызывается Java-стороной в цикле (game loop),
 * поэтому не должна блокировать надолго. */
int host_ui_poll_event(void);

/* UI.sleepMs(ms) — пауза для тайминга кадров/циклов в Java-программе.
 * Реализация хоста сама решает, как спать (usleep/NSThread sleep), важно
 * только не спать на главном потоке хоста (VM и так в отдельном потоке). */
void host_sleep_ms(int ms);

#ifdef __cplusplus
}
#endif

#endif
