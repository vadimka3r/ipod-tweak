// UI.java — заглушка для javac, как и Native.java: тела не исполняются,
// interp.c перехватывает вызовы UI.* по имени класса (см. call_native).
public class UI {
    static void label(int handle, int x, int y, int w, int h, String text) {}
    static void button(int handle, int x, int y, int w, int h, String text) {}
    static void setText(int handle, String text) {}
    static void remove(int handle) {}
    static int pollEvent() { return -1; }
    static void sleepMs(int ms) {}
}
