package training.jdk8.interfaces.def;

public interface DefaultInterface {
    void method1(String str);

    default void log(String message) {
        System.out.println("DefaultInterface Logging" + message);
    }

    default void log2(String message) {
        System.out.println("DefaultInterface Logging" + message);
    }

    static void print(String str) {
        System.out.println("Printing " + str);
    }


    //trying to override Object method gives compile time error as
    //"A default method cannot override a method from java.lang.Object"
//	default String toString(){
//		return "i1";
//	}



}
