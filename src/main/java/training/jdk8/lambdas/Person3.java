package training.jdk8.lambdas;

import java.util.Objects;

public class Person3 {
	String name;
	
	
	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Person3(String name) {
		super();
		this.name = name;
	}
	
	@Override
	public int hashCode() {
		int hash = 1;
		hash = hash*31 + ((name==null) ? 0 : name.hashCode());		
//		Objects.hash(name);
		return hash;
	}
	
	@Override
	public boolean equals(Object o) {
		// 1st: Check for reference equality
		if (this == o) return true;
		
		// 2nd: Check if the object is null
		if (o == null) return false;
		
		// 3th: Check for classes equality
		if (this.getClass() != o.getClass()) return false;
		
		//4th Check for properties equality
		
//		return Objects.equals(name, o.getName());
		Person3 obj = (Person3) o;
		if (name == null) {
			if (obj.getName()!=null)
				return false;
		}else {
			if (!name.equals(obj.getName()))
				return false;
		}
		
		return true;
	}
}
