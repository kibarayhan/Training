package training.jdk8.lambdas;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.function.DoubleSupplier;
import java.util.stream.Collectors;

/*
 * NA -> T
A Supplier takes no arguments and returns a value of a known type. 
Fetching, reading or creating resources to be used by other functions 
are common use cases. Suppliers get things started.

The Supplier, as the name suggests, supplies us with a result

For example, fetching configuration values from database, loading with reference data,
creating an list of students with default identifiers etc, can all be represented by a supplier function
 */
public class Suppliers {

	public static void main(String[] args) {

		// Anonymous inner class
		DoubleSupplier randomSupplier = new DoubleSupplier() {
			@Override
			public double getAsDouble() {
				return Math.random();
			}
		};

		// Lambda expression
		randomSupplier = () -> Math.random();

		// Method reference
		randomSupplier = Math::random;

		System.out.println(randomSupplier.getAsDouble());		
		
		List<String> names = Arrays.asList("Mal", "Wash", "Kaylee", "Inara", "Zoe", "Jayne", "Simon", "River",
				"Shepherd Book");
		Optional<String> startWithC = names.stream().filter(name->name.startsWith("C")).findFirst();
		// Prints Optional.empty
		System.out.println(startWithC);
		// Prints None
		System.out.println(startWithC.orElse("None"));
		// Forms the comma-separated collection, even when name is found
		System.err.println(startWithC.orElse(String.format("Not result found in %s", names.stream().collect(Collectors.joining(",")))));
		// Forms the comma-separated collection only if the Optional is empty
		System.err.println(startWithC.orElseGet(() -> String.format("Not result found in %s", names.stream().collect(Collectors.joining(",")))));
		
	}
}
