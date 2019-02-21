package training.jdk8.lambdas;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.function.BinaryOperator;
import java.util.function.Function;
import java.util.function.ToIntFunction;
import java.util.stream.Collectors;

/*
 * T -> R
 * A Function transforms data. 
 *
 * We use a Function for maps, and transformation purposes, such as 
 * converting temperature from Centigrade to Fahrenheit,
 * transforming a String to an Integer, etc
 *
 * It is important to not mutate the original data that is passed in.
 */
public class Functions {

	public static void main(String[] args) {
		sampleFunctions();

		List<String> names = Arrays.asList("Mal", "Wash", "Kaylee", "Inara", "Zoë", "Jayne", "Simon", "River",
				"Shepherd Book");

		lengthOfStrings(names);
		
		combineStrings(names);
	}

	private static void sampleFunctions() {
		// convert centigrade to fahrenheit
		Function<Integer, Double> centigradeToFahrenheitInt = x -> Double.valueOf((x * 9 / 5) + 32);
		// String to an integer
		Function<String, Integer> stringToInt = x -> Integer.valueOf(x);

		// tests
		Integer centigrade = Integer.valueOf(20);
		System.out.println("Centigrade to Fahrenheit: " + centigradeToFahrenheitInt.apply(centigrade));
		System.out.println(" String to Int: " + stringToInt.apply("4"));
	}

	private static void lengthOfStrings(List<String> names) {
		List<Integer> nameLengths = names.stream().map(new Function<String, Integer>() {
			@Override
			public Integer apply(String s) {
				return s.length();
			}
		}).collect(Collectors.toList());
		
		nameLengths = names.stream().map(s -> s.length()).collect(Collectors.toList());
		
		nameLengths = names.stream().map(String::length).collect(Collectors.toList());
		System.out.printf("nameLengths = %s%n", nameLengths);
		
		names.stream().mapToInt(new ToIntFunction<String>() {
			@Override
			public int applyAsInt(String value) {
				return value.length();
			}
		});
		// nameLengths == [3, 4, 6, 5, 3, 5, 5, 5, 13]
	}

	private static void combineStrings(List<String> names) {
		BinaryOperator<String> accumulator = (f, s) -> {
			return new StringBuilder(f).append(",").append(s).toString();
		};
		
		Optional<String> namesAsAStr = names.stream().reduce(accumulator);
		System.out.println(namesAsAStr.orElse("No names"));
		
		String namesAsString = names.stream().collect(Collectors.joining(","));
		System.out.println(namesAsString);
	}

}
