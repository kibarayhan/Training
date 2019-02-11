package training.j8interface.def;

public class DefaultInterfaceImpl implements DefaultInterface, DefaultInterface2 {

    @Override
    public void method1(String str) {

    }

    @Override
    public void method2(String str) {

    }

    @Override
    public void log(String message) {
        System.out.println("MyClass logging::" + message);
        DefaultInterface.print("abc");
    }

}
