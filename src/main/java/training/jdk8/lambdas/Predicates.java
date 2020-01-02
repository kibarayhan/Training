package training.jdk8.lambdas;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.function.Predicate;
import java.util.stream.Collectors;

/*
 * (T) -> Boolean (true/false);
 *
 * A Predicate returns true or false. These are used for filters or replacing big chains of if/else logic.
 * We need a function for checking a condition. 
 * A Predicate is one such function accepting a single argument to evaluate to a boolean result.
 * It has a single method test which returns the boolean value
 */
public class Predicates {

    public static void main(String[] args) {
        // Lambda to check an empty string
        Predicate<String> emptyStringChecker = s -> s.isEmpty();
        // Given a number n returns a boolean indicating if it is odd.
        Predicate<Integer> isOdd = n -> n % 2 != 0;
        // Given a character c returns a boolean indicating if it is equal to ‘y’.
        Predicate<Character> isCharEqualY = c -> c == 'y';

        Collection<Integer> items = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8);
        MyPredicate<Integer> isOddMy = n -> n %2 != 0;
        Collection<Integer> oddItems = myFilter(isOddMy, items);
        oddItems.forEach(i -> System.out.println(i));


        oddItems = items.stream().filter(isOdd).collect(Collectors.toList());
        System.out.println("\n"+oddItems);
    }

    public interface MyPredicate<T> {
        boolean test(T input);
    }

    public static <T> Collection<T> myFilter (MyPredicate<T> predicate, Collection<T> items){
        Collection<T> filteredItems = new ArrayList<T>();
        for (T item: items){
            if (predicate.test(item)){
                filteredItems.add(item);
            }
        }
        return filteredItems;
    }


}
