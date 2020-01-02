package training.jdk8.interfaces.defaultMethods;

public class MultipleInheritance {

	interface Person{
		default String getName() {
			return "Person";
		}
	}
	
	interface Ayhan extends Person{
		default String getName() {
			return "Ayhan";
		}
	}
		
	class MultipleInheritance1 implements Ayhan, Person{
	}
	
	
	interface Veli{
		default String getName() {
			return "Veli";
		}
	}
	
	// Note: You must override the function to get compiler happy
	class MultipleInheritance2 implements Veli, Person{
		@Override
		public String getName() {
			return Person.super.getName();
		}
	}
	
	public static void main(String[] args) {
		MultipleInheritance x = new MultipleInheritance();
		System.out.println(x.new MultipleInheritance1().getName());
		System.out.println(x.new MultipleInheritance2().getName());
	}
}
