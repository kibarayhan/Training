package training.jdk8.lambdas.basic;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import training.jdk8.lambdas.Person;

public class ConstructorReferences {

	public static void main(String[] args) {
		methodReferenceUsage1();
		copyConstructorUsage();
		varargsConstructorUsage();
		arraysUsage();
	}

	
	
	private static void arraysUsage() {
		List<String> names = Arrays.asList("ayhan kibar", "ali deli", "veli meli");
		Person[] people = names.stream().map(Person::new).toArray(Person[]::new);
	}



	private static void varargsConstructorUsage() {
		List<String> names = Arrays.asList("ayhan kibar", "ali deli", "veli meli");
		
		List<Person> persons = names.stream()
		.map(name -> name.split(" "))
		.map(Person::new)
		.collect(Collectors.toList());
		System.out.println("");
		persons.forEach(System.out::println);		
	}
	
	private static void methodReferenceUsage1() {
		List<String> names = Arrays.asList("ayhan", "ali", "veli");
		List<Person> persons = names.stream().map(name -> new Person(name)).collect(Collectors.toList());
		persons = names.stream().map(Person::new).collect(Collectors.toList());
		persons.forEach(System.out::println);
	}

	private static void copyConstructorUsage() {
		Person before = new Person("Ayhan");
		List<Person> people = Stream.of(before).collect(Collectors.toList());
				
		Person after1 = people.get(0);
		assertTrue(before == after1);
		assertTrue(before.equals(after1));

		people = Stream.of(before).map(Person::new).collect(Collectors.toList());
		Person after2 = people.get(0);
		assertFalse(before == after2);
		assertTrue(before.equals(after2));
	}

}
