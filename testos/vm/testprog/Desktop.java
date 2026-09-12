// Desktop.java — первый настоящий "рабочий стол": не завершается, живёт в
// вечном цикле, показывает метку и кнопку, реагирует на тап. В отличие от
// UITest.java (одноразовый тест) — это то, что реально будет висеть на
// экране айпода постоянно.
//
// ВАЖНО: наша VM (M1/M4) пока не умеет `new`, invokevirtual/invokespecial,
// поэтому конкатенация строк через "+" (которую javac компилирует в
// StringBuilder) здесь не сработает — используем только строковые
// литералы и int-арифметику. Полноценные строки — в M2.
public class Desktop {
    public static void main(String[] args) {
        UI.label(1, 10, 10, 280, 30, "testOS desktop");
        UI.button(2, 10, 50, 150, 44, "Tap me");

        int taps = 0;
        while (true) {
            int handle = UI.pollEvent();
            if (handle == 2) {
                taps = taps + 1;
                if (taps == 1) UI.setText(1, "taps: 1");
                else if (taps == 2) UI.setText(1, "taps: 2");
                else if (taps == 3) UI.setText(1, "taps: 3");
                else UI.setText(1, "taps: many");
            }
            UI.sleepMs(50);
        }
    }
}
