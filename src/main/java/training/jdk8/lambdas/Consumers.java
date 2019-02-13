package training.jdk8.lambdas;

import java.util.function.Consumer;
import java.util.stream.Stream;

/*
 * (T) -> (NA)
 * The Consumer accepts a single argument but does not return any result.
 * Consumers are where mutating functions, things with side-effects, should go. 
 * Consumers finish things
  
 * This is mostly used to perform operations on the arguments such as
 * persisting the employees, invoking house keeping operations, emailing newsletters etc.
*/
public class Consumers {

    public static void main(String[] args) {
        Consumer<Integer> printer = System.out::println;
        Stream.of(3, 1, 4, 1, 5, 9).forEach(printer);
    }
}
