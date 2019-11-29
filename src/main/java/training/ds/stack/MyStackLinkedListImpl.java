package training.ds.stack;

import java.util.EmptyStackException;

public class MyStackLinkedListImpl<T> {
    private MyStackNode<T> top;

    public T pop(){
        if (isEmpty()) throw new EmptyStackException();
        T data = top.data;
        top = top.next;
        return data;
    }

    public T peek(){
        if (isEmpty()) throw new EmptyStackException();
        return top.data;
    }

    public void push(T data){
        MyStackNode<T> newTop = new MyStackNode<>(data);
        newTop.next = top;
        top = newTop;
    }

    public boolean isEmpty(){
        return top==null;
    }

    private static class MyStackNode<T>{
        T data;
        MyStackNode<T> next;

        public MyStackNode(T data){
            this.data = data;
        }
    }
}
