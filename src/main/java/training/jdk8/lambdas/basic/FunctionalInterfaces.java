package training.jdk8.lambdas.basic;

import java.util.function.Predicate;
import java.util.stream.Stream;

/*
 * Create an interface with a single, abstract method, and add the @FunctionalInterface annotation.
 */
public class FunctionalInterfaces {

	public static void main(String[] args) {
		FunctionalInterfaces f = new FunctionalInterfaces();
		f.predicateUSage();
	}
	
	public void predicateUSage() {
		Predicate<String> isPolindrome = s -> new StringBuilder(s).reverse().toString().equalsIgnoreCase(s); 
		Predicate<String> isPolindrome2 = s -> {
			StringBuilder sb = new StringBuilder(s);
			boolean result = sb.reverse().toString().equalsIgnoreCase(s);
			return result;
		};
		Predicate<String> isPolindrome3 = s-> new PalindromeCheckerImpl().isPolindrome(s);		
		Stream.of("TactCoa", "atcocta").filter(isPolindrome3).forEach(System.out::println);		
	}
	
	@FunctionalInterface
	public interface PalindromeChecker{
		boolean isPolindrome(String s);
	}
	
	public class PalindromeCheckerImpl implements PalindromeChecker{
		@Override
		public boolean isPolindrome(String s) {
			return new StringBuilder(s).reverse().toString().equalsIgnoreCase(s);
		}
		
	}
}
