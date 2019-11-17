package training.jdk8.lambdas.basic;

import java.util.Arrays;
import java.util.List;
import java.util.function.Consumer;

public class Lambdas {

	public static void main(String[] args) {
		List<Integer> values = Arrays.asList(1, 5, 10, 20, 30);

		//
		for (Integer value : values) {
			System.out.println(String.format("using for each %d", value));
		}

		//
		values.forEach(new Consumer<Integer>() {
			@Override
			public void accept(Integer value) {
				System.out.println(String.format("using Consumer %d", value));
			}
		});

		//
		values.forEach(e -> System.out.println(String.format("using lambda %d", e)));
		
		values.forEach(System.out::println);
		//
		values.forEach(e -> {
			System.out.println(String.format("using lambda %d", e));
			System.out.println(String.format("using lambda %d", e));
		});

		// below codes are equal
		values.sort((e1, e2) -> e1.compareTo(e2));
		values.sort((e1, e2) -> {
			int result = e1.compareTo(e2);
			return result;
		});

	}
}
