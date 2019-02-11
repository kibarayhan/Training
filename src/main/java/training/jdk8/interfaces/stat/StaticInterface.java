package training.jdk8.interfaces.stat;

public interface StaticInterface {

    default void print(String str) {
        if (!isNull(str))
            System.out.println("MyData Print::" + str);
    }

    default boolean isNull(String str) {
//    static boolean isNull(String str) {
        System.out.println("Interface Null Check.");

        return str == null ? true : "".equals(str) ? true : false;
    }
}
