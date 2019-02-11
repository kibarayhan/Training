package training.j8interface.stat;

import java.util.List;
import java.util.stream.IntStream;

public class StaticInterfaceImpl implements StaticInterface {

    public boolean isNull(String str) {
        System.out.println("Impl Null Check");

        return str == null ? true : false;
    }

    public static void main(String args[]) {
        StaticInterfaceImpl impl = new StaticInterfaceImpl();
        impl.print("");
        impl.isNull("test");
    }

    private static boolean isPrime(int number) {
        return number > 1
                && IntStream.range(2, number).noneMatch(
                index -> number % index == 0);
    }


    public static int sumOfIntegersGreaterthan10(List<Integer> integerList) {
        return integerList.parallelStream().filter(i -> i > 10).mapToInt(i -> i).sum();
    }
}
