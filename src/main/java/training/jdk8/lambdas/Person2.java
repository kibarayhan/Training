package training.jdk8.lambdas;

import java.util.Objects;

public class Person2 {
	private final int id;
	private String name;
	
	public Person2 (Person2 person) {
		this.id = person.id;
		this.name = person.name;
	}

	public Person2 (final int id, Person person) {
		this.id = id;
		this.name = person.getName();
	}

	public Person2(final int id, final String name) {
		this.id = id;
		this.name = name;
	}
	
	@Override
	public String toString() {
		return String.format("%s, [id = %d, name = %s]", getClass().getSimpleName(), id, name);
	}

	@Override
	public boolean equals(Object obj) {
		//1. check references
		if (this == obj) {
			return true;
		}

		// 2. check null reference
		if (obj == null) {
			return false;
		}
		
		
		// 3. check types
		if (getClass() != obj.getClass()){
			return false;
		}
		
		// 4. check individual other properties
		Person2 person = (Person2) obj;
		if ( !Objects.equals(this.id, person.id)) {
			return false;
		}else if ( !Objects.equals(this.name, person.name)) {
			return false;
		}
		
		return true;
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		
		result = result * prime + id;
		result = result * prime + (name == null? 0 : name.hashCode());
		
		return result;
	}
	
	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getId() {
		return id;
	}
}
