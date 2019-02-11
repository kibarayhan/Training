package training.jdk8.lambdas;

import java.util.function.Function;

/*
 A Function is a functional interface whose sole purpose is to return any result by working on a single input argument.
 It accepts an argument of type T and returns a result of type R, by applying specified logic on the input via the
 apply method.

 We use a Function for transformation purposes, such as converting temperature from Centigrade to Fahrenheit,
 transforming a String to an Integer, etc
 */
public class Functions {

    public static void main(String[] args) {
        // convert centigrade to fahrenheit
        Function<Integer, Double> centigradeToFahrenheitInt = x -> Double.valueOf((x * 9 / 5) + 32);
        // String to an integer
        Function<String, Integer> stringToInt = x -> Integer.valueOf(x);

        // tests
        Integer centigrade = Integer.valueOf(20);
        System.out.println("Centigrade to Fahrenheit: " + centigradeToFahrenheitInt.apply(centigrade));
        System.out.println(" String to Int: " + stringToInt.apply("4"));
    }

}
