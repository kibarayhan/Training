package training.jdk8.interfaces;

public class FunctionalInterfaces{

	public static void main(String[] args) {
		
	}
	
	public class Test implements FunctionalInterface1{
		@Override
		public void method() {
		}		
	}
	
	@FunctionalInterface
	interface FunctionalInterface1 {
		void method();
	}

	@FunctionalInterface
	interface FunctionalDefaultMethods {
		void method();

		default void defaultMethod() {
		}
		
		static void staticMethod() {
		}
	}

}
