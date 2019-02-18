package training.jdk8.lambdas.basic;

import java.util.function.Predicate;

/*
 * Create an interface with a single, abstract method, and add the @FunctionalInterface annotation.
 */
public class FunctionalInterfaces {

	public static void main(String[] args) {
		
	}
	
	public FunctionalInterfaces(){
		Predicate<String> isPolindrome = s -> new StringBuilder(s).reverse().toString().equalsIgnoreCase(s); 
		Predicate<String> isPolindrome2 = s -> {
			StringBuilder sb = new StringBuilder(s);
			return sb.reverse().toString().equalsIgnoreCase(s);
		};
	}
	
	@FunctionalInterface
	public interface PalindromeChecker{
		boolean isPolindrome(String s);
	}
	
	public class PalindromeCheckerImpl implements PalindromeChecker{

		@Override
		public boolean isPolindrome(String s) {
//			if (s.)
			return false;
		}
		
	}
}
