package training.jdk8.lambdas;


import org.jetbrains.annotations.NotNull;

import java.security.PrivilegedAction;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.function.BiFunction;
import java.util.function.BinaryOperator;
import java.util.function.Function;
import java.util.function.Predicate;

public class LambdaExpression {

    public static void main (String[] args){
        BinaryOperator<Integer> sum = (x, y) -> x + y;
        Callable<Integer> callMe42 = () -> 42;
        Callable<Double> callMePi = () -> { return 3.14;};
        Callable<String> callMeHello = () -> "Hello";
        PrivilegedAction<String> action = () -> "Hello";
        Runnable runner = () -> { System.out.println("Hello World!"); };
        BiFunction<Integer, Integer, String> sumOf2IntegerAsString = (x,y) -> Integer.toString(x+y) ;
    }
}
