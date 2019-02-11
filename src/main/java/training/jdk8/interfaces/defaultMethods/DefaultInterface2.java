package training.jdk8.interfaces.defaultMethods;

public interface DefaultInterface2 {
    void method2(String str);

    default void log(String message) {
        System.out.println("DefaultInterface2 Logging" + message);
    }
}
