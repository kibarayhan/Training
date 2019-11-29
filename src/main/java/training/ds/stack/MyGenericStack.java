package training.ds.stack;

import java.util.ArrayList;
import java.util.List;

public class MyGenericStack<T> {
    private static int MAX_SIZE;
    private List<T> items;

    public MyGenericStack(int size) {
        MAX_SIZE = size;
        items = new ArrayList<>(MAX_SIZE);
    }

    public MyGenericStack() {
        items = new ArrayList<>(MAX_SIZE);
    }

    public T pop() {
        if (isEmpty()) throw new IndexOutOfBoundsException("Stack is empty!");

        T item = items.get(items.size() - 1);
        items.remove(item);
        return item;
    }

    public T peek() {
        return items.get(items.size() - 1);
    }

    public void push(T item) {
        if (isFull()) throw new IndexOutOfBoundsException("Stack is full!");
        items.add(item);
    }

    public boolean isEmpty() {
        return items.isEmpty();
    }

    public boolean isFull() {
        return items.size() >= MAX_SIZE;
    }

}
