// Test.java — проверка M1: арифметика, цикл, ветвление, вызов своего метода,
// печать строки и чисел через "нативные" методы.
public class Test {
    static int square(int x) {
        return x * x;
    }

    public static void main(String[] args) {
        Native.println("testos M1: hello from Java bytecode");
        int i = 1;
        while (i <= 5) {
            Native.println(square(i));
            i = i + 1;
        }
        Native.println("done");
    }
}
