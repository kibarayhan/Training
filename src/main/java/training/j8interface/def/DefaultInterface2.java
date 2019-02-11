package training.j8interface.def;

public interface DefaultInterface2 {
    void method2(String str);

    default void log(String message) {
        System.out.println("training.j8interface.def.DefaultInterface2 Logging" + message);
    }
}
