package training.jdk8.interfaces.def;

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
        DefaultInterface.super.log("abc1");
        DefaultInterface.print("abc2");
    }

}
