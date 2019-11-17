package training.jdk8.interfaces.staticMethods;

import java.util.function.Predicate;

public interface StaticInterface {

    default void print(String str) {
        if (!isNull(str))
            System.out.println("MyData Print::" + str);
    }

//    default boolean isNull(String str) {
    static boolean isNull(String str) {
        System.out.println("Interface Null Check.");
        return str == null ? true : "".equals(str) ? true : false;
    }

    // is Null implementing with lambdas
    static boolean isNullWithLambda(String s) {
    	System.out.println("Interface Null Check with Lambda.");
    	Predicate<String> isNull = (s1) -> (s1 ==null ? null : "".equals(s1)? true:false);
    	return isNull.test(s);
    }
    
    // After Java 9 it is possible to have private methods in interface 
//    private void privateMethod() {
//    	
//    }
    
}
