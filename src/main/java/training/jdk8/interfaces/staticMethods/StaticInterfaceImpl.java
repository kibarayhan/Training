package training.jdk8.interfaces.staticMethods;

import java.util.List;
import java.util.function.Predicate;
import java.util.stream.IntStream;

/*
 * The key points to remember are:
	- Static methods must have an implementation
	- You cannot override a static method
	- Call static methods from the interface name
	- You do not need to implement an interface to use its static methods
 */
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
        Predicate<Integer> greateThen10 = i -> i > 10;
        return integerList.parallelStream().filter(greateThen10).mapToInt(i -> i).sum();
    }
}
