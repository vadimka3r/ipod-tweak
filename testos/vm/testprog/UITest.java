// UITest.java — проверка M4-моста: создать метку и кнопку, несколько
// "тиков" опросить события (на консоли событий не будет — это нормально,
// проверяем что цикл не падает), убрать элементы.
public class UITest {
    public static void main(String[] args) {
        UI.label(1, 10, 10, 200, 30, "testOS desktop");
        UI.button(2, 10, 50, 100, 40, "Click me");

        int i = 0;
        while (i < 3) {
            int handle = UI.pollEvent();
            if (handle == 2) {
                UI.setText(1, "button clicked!");
            }
            UI.sleepMs(50);
            i = i + 1;
        }

        UI.remove(1);
        UI.remove(2);
        Native.println("UI test done");
    }
}
