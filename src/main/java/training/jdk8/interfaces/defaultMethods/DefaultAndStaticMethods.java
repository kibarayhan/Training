package training.jdk8.interfaces.defaultMethods;

import java.util.function.Supplier;

public class DefaultAndStaticMethods {

	public static void main(String[] args) {
		Defaultable defaulable = DefaulableFactory.create(DefaultableImpl::new);
		System.out.println( defaulable.notRequired() );
		
		defaulable = DefaulableFactory.create(OverridableImpl::new);
		System.out.println( defaulable.notRequired() );
	}

	private interface Defaultable {
		// Interfaces now allow default methods, the implementer may or
		// may not implement (override) them.
		default String notRequired() {
			return "Default implementation";
		}
	}

	private static class DefaultableImpl implements Defaultable {
	}

	private static class OverridableImpl implements Defaultable {
		@Override
		public String notRequired() {
			return "Overridden implementation";
		}
	}

	private interface DefaulableFactory {
		// Interfaces now allow static methods
		static Defaultable create(Supplier<Defaultable> supplier) {
			return supplier.get();
		}
	}
}
