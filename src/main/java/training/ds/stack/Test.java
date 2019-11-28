package training.ds.stack;

import java.util.function.IntPredicate;
import java.util.function.Predicate;
import java.util.stream.IntStream;

public class Test {

	public static void main(String[] args) {
		MyStack stack = new MyStack();
		try {
			stack.push("1");
			System.out.println(stack.pop());
			System.out.println(stack.pop());
		} catch (Exception e) {
			e.printStackTrace();
		}

		//
//		Runnable r2 = new Runnable() {
//			@Override
//			public void run() {
//				System.out.println("testR2");
//			}
//		};
//
//		int number = 13;
//		IntPredicate isDivisible = index -> number % index == 0;
//		Predicate<Integer> p1 = index -> number % index == 0;
//		System.err.println(IntStream.range(2, number).noneMatch(isDivisible));
//
//
//
//		Runnable r1 = () -> System.out.println("testR1");
//		r1.run();


	}
}
