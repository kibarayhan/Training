package training.jdk8.lambdas;

import java.util.Arrays;
import java.util.Objects;
import java.util.stream.Collectors;

public class Person {
	
	private final String name;
	
	public Person(String... names) {
		System.out.println("Varargs ctor, names=" + Arrays.asList(names));
		name = Arrays.stream(names).collect(Collectors.joining(" "));
	}
	
	public Person (Person person) {
		name = person.name;
	}
	
	public Person (String name){
		this.name = name;
	}

	public String getName() {
		return name;
	}
	
	@Override
	public String toString() {
		return String.format("%s [name = %s]", getClass().getSimpleName(), getName());
	}

//	@Override
//	public int hashCode() {
//		return Objects.hash(name);
//	}

	@Override
	public int hashCode() {
		int hash = 1;
		hash = hash*31 + ((name == null) ? 0 : name.hashCode());
		return hash;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Person other = (Person) obj;
		return Objects.equals(name, other.name);
	}

	
//	// Step 0: Please add the @Override annotation, it will ensure that your
//	// intention is to change the default implementation.
//	@Override
//	public boolean equals(Object obj) {
//	// Step 1: Check if the "obj" is pointing to the this instance
//		if (this == obj)
//			return true;
//	
//		// Step 2: Check if the "obj" is null
//		if (obj == null)
//			return false;
//		
//		// Step 3: Check classes equality. Note of caution here: please do not use the
//		// "instanceof" operator unless class is declared as final. It may cause
//		// an issues within class hierarchies.
//		if (getClass() != obj.getClass())
//			return false;
//		
//		// Step 4: Check individual fields equality
//		Person other = (Person) obj;
//		if (!Objects.equals(name, other.getName())) {
//			return false;
//		}
////		if (name == null) {
////			if (other.name != null)
////				return false;
////		} else if (!name.equals(other.name))
////			return false;
//		return true;
//	}
	
	

}
