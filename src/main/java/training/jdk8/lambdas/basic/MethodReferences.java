package training.jdk8.lambdas.basic;

import java.util.Arrays;
import java.util.List;
import java.util.function.Consumer;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class MethodReferences {

	// Class that provides the functionality via it's method
    public class AddableUtil {
      public int addThemUp(int i1, int i2){
        return i1+i2;
      }
    }
	
    interface IAddable{
    	public int addThemUp(int i1, int i2);
    }
	
    public static void main(String[] args) {
    	
    	
    	IAddable addableViaMethodReference = new MethodReferences().new AddableUtil()::addThemUp;
    	System.out.println(addableViaMethodReference.addThemUp(1, 2));
    	
        // Using a lambda expression
        Stream.of(3, 1, 4, 1, 5, 9).forEach(x -> System.out.println(x));
        // Using a method reference
        Stream.of(3, 1, 4, 1, 5, 9).forEach(System.out::println);

        // Assigning the method reference to a functional interface
        Consumer<Integer> printer = System.out::println;
        Stream.of(3, 1, 4, 1, 5, 9).forEach(printer);        
        Arrays.stream(new int[] {1,4,5,7,8}).boxed().forEach(printer);
        
        List<String> strings = Arrays.asList("this", "is", "a", "list", "of", "strings");
        List<String> sorted1 = strings.stream()
                .sorted((s1, s2) -> s1.compareTo(s2))
                .collect(Collectors.toList());

        List<String> sorted2 = strings.stream()
                .sorted(String::compareTo)
                .collect(Collectors.toList());
    }
    
}
