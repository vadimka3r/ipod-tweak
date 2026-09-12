// Native.java — заглушка для компиляции javac'ом. Тела методов никогда не
// исполняются нашей мини-JVM: интерпретатор перехватывает вызовы
// Native.println/print ДО того, как дошёл бы до их байткода (см. call_native
// в interp.c). Реальные тела здесь не важны, важна только сигнатура.
public class Native {
    static void println(int x) {}
    static void print(String s) {}
    static void println(String s) {}
}
