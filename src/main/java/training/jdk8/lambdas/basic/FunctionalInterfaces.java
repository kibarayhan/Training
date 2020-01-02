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
		Predicate<String> isPolindrome3 = s-> new PolindromeCheckerImpl().isPolindrome(s);
		Stream.of("TactCoa", "atcocta").filter(isPolindrome3).forEach(System.out::println);
		Stream.of("TactCoa", "atcocta").filter(new PolindromeCheckerImpl()::isPolindrome2);
		Stream.of("TactCoa", "atcocta").filter(PolindromeChecker::isPolindrome3);
	}
	
	@FunctionalInterface
	public interface PolindromeChecker {
		boolean isPolindrome(String s);

		default boolean isPolindrome2(String s){
			return isPolindrome3(s);
		}
		static boolean isPolindrome3(String s){
			return new StringBuilder(s).reverse().toString().equalsIgnoreCase(s);
		}
	}
	
	public class PolindromeCheckerImpl implements PolindromeChecker {
		@Override
		public boolean isPolindrome(String s) {
			return new StringBuilder(s).reverse().toString().equalsIgnoreCase(s);
		}
		
	}
}
