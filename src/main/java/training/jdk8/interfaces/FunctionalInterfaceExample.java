package training.jdk8.interfaces;

//https://www.oreilly.com/learning/whats-new-in-java-8-lambdas

public class FunctionalInterfaceExample {

	@FunctionalInterface
	interface IOdd {
		public boolean isOdd(Integer input);
	}

	@FunctionalInterface
	interface IEven {
		public boolean isEven(Integer input);

		public static void aStaticMethod() {
		}

		public default void aDefaultMethod() {
		}
	}

	@FunctionalInterface
	interface IAddable<T> {
		public T add(T input1, T input2);
	}

	@FunctionalInterface
	interface IConcat {
		public String concat(String delimiter, String... input);
	}

	public static void main(String[] args) {
		IAddable<String> concateStrings1 = (String s1, String s2) -> s1 + s2;

		IAddable<String> concateStrings2 = (s1, s2) -> s1 + s2;

		IAddable<String> concateStringsUsingBuffer = (String s1, String s2) -> {
			return new StringBuffer(s1).append(" ").append(s2).toString();
		};
		System.out.println("concate strings: " + concateStringsUsingBuffer.add("ayhan", "kibar"));

		IAddable<Integer> multiply = (i1, i2) -> i1 * i2;

		IEven even = i -> (i % 2) == 0;
		IOdd odd = i -> (i % 2) == 1;

		System.out.println("is 5 odd: " + odd.isOdd(5));
		System.out.println("is 5 even: " + even.isEven(5));

		// pre Java8 using anonymous classes
		IConcat preJava8 = new IConcat() {			
			@Override
			public String concat(String delimiter, String... input) {
				StringBuffer stringBuffer = new StringBuffer();
				for (String str : input) {
					stringBuffer.append(str).append(delimiter);
				}
				return stringBuffer.toString();
			}
		};
		
		// Java8 using lambda
		IConcat concat = (delimiter, inputs) -> {
			StringBuffer stringBuffer = new StringBuffer();
			for (String str : inputs) {
				stringBuffer.append(str).append(delimiter);
			}
			return stringBuffer.toString();
		};

		System.out.println("concate many strings: " + concat.concat("Ali", "Veli", "deli"));
		System.out.println("concate many strings2: " + concat.concat(",", new String[] { "Ali2", "Veli2", "deli2" }));
		
		
		// examples for Runnable functional interface
		// example implementation
		new Thread(new Runnable() {
		  @Override
		  public void run() {
			  System.out.println("do something.");
		  }
		}).start();
		
		// The constructor now takes in a lambda
		new Thread(()-> System.out.println("stop me")).start();
		
		// passing lambda to a constructor
		Runnable doSomething = () -> System.out.println("Do mething."); 
		new Thread(doSomething).start();
		
		
		
	}
}
