package training.jdk8.lambdas.basic;

import java.util.function.Predicate;

/*
 * Create an interface with a single, abstract method, and add the @FunctionalInterface annotation.
 */
public class FunctionalInterfaces {

	public static void main(String[] args) {
		
	}
	
	public FunctionalInterfaces(){
		Predicate isPolindrome = s -> s.equals(s); 
		Predicate isPolindrome2 = s -> {
//			if (s.toString().re)
			return s.equals(s); 
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
