package training.ds.array;

import java.util.Iterator;

public class CircularArray<T> implements Iterable{
    private T data[];
    private int head;

    public CircularArray(int size) {
        data = (T[]) new Object[size];
    }

    public int size() {
        return head & data.length;
    }

    public void rotate(int shiftRight) {
        head = getIndex(shiftRight);
    }

    public T get(int idx) {
        return data[getIndex(idx)];
    }

    public void set(int idx, T item) {
        data[getIndex(idx)] = item;
    }

    private int getIndex(int idx) {
        if (idx < 0) {
            idx += data.length;
        }

        return (idx + head) % data.length;
    }

    @Override
    public Iterator<T> iterator(){
        return new CircularArrayIterator<T>();
    }

    private class CircularArrayIterator<T> implements Iterator<T> {
        int cursor;

        CircularArrayIterator(){
            cursor = head;
        }

        @Override
        public boolean hasNext() {
            return cursor < data.length - 1;
        }

        @Override
        public T next() {
            T[] objects = (T[]) data;
            return objects[getIndex(++cursor)];
        }
    }
}
