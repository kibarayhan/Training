package training.ds.queue;

import java.util.NoSuchElementException;

public class MyQueueLinkedListImpl<T> {
    MyQueueItem<T> first;
    MyQueueItem<T> last;

    public void add(T data) {
        MyQueueItem<T> item = new MyQueueItem<>(data);
        if (last != null){
            last.next = item;
        }
        last = item;
        if (first == null){
            first = last;
        }
    }

    public T remove() {
        if (isEmpty()) throw new NoSuchElementException();
        T data = first.data;
        first = first.next;
        if (first == null){
            last = null;
        }
        return data;
    }

    public T peek() {
        if (isEmpty()) throw new NoSuchElementException();
        return first.data;
    }


    public boolean isEmpty() {
        return first == null;
    }

    private static class MyQueueItem<T> {
        T data;
        MyQueueItem<T> next;

        public MyQueueItem(T data) {
            this.data = data;
        }

    }
}
