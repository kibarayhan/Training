package training.ds.hash;

import java.util.HashMap;
import java.util.Map;

class LRUCache {
    Map<Integer, MyEntry> map;
    int size;
    MyEntry head, tail;
    int capacity;

    public LRUCache(int capacity) {
        this.map = new HashMap<>(capacity);
        this.capacity = capacity;

        head = new MyEntry(0, 0);
        tail = new MyEntry(0, 0);
        head.next = tail;
        tail.prev = head;
    }

    private void moveToHead(MyEntry item){
        remove(item);
        add(item);
    }

    private void addForFirst(MyEntry item){
        item.next = tail;
        item.prev = tail.prev;

        item.prev.next = item;
        tail.prev = item;
    }


    private void add(MyEntry item){
        item.next = head.next;
        item.prev = head;

        item.next.prev = item;
        head.next = item;
    }

    private void remove(MyEntry item){
        MyEntry pre = item.prev;
        MyEntry next = item.next;

        pre.next = next;
        next.prev = pre;
    }

    private void popTail(){
        MyEntry pre = tail.prev;
        remove(pre);
        map.remove(pre.key);
    }

    public int get(int key) {
        MyEntry item = map.get(key);
        if (item != null){
            moveToHead(item);
        }
        return item!=null ? item.value : -1;
    }

    public void put(int key, int value) {
        MyEntry item = map.get(key);
        if (item == null){
            if (size == capacity) {
                popTail();
                size--;
            }
            item = new MyEntry(key, value);
            map.put(key, item);
            addForFirst(item);
            size++;
        }else{
            item.value = value;
            moveToHead(item);
        }
    }

    private class MyEntry{
        int key;
        int value;
        MyEntry prev;
        MyEntry next;

        public MyEntry(int k, int v){
            key = k;
            value = v;
        }
    }

    public static void main(String[] args) {
        LRUCache cache  = new LRUCache(3);

        cache.put(2, 2);                        // add 2
        cache.put(1, 1);                        // add 1
        System.out.println(cache.get(2));       // returns 2

        System.out.println(cache.get(1));       // returns 1
        System.out.println(cache.get(2));       // returns 2
        cache.put(3, 3);                        // add 3
        cache.put(4, 4);                        // evicts key 3
        System.out.println(cache.get(3));       // returns -1 (not found)
        System.out.println(cache.get(2));       // returns 2.
        System.out.println(cache.get(1));       // returns 1.
        System.out.println(cache.get(4));       // returns 4.


//        cache.put(10, 13);
//        cache.put(3, 17);
//        cache.put(6, 11);
//        cache.put(10, 5);
//        cache.put(9, 10);
//
//        System.out.println(cache.get(13));        // returns null
//        cache.put(2, 19);
//        System.out.println(cache.get(2));       // returns 19
//        System.out.println(cache.get(3));       // returns 7
//        cache.put(5, 25);
//        System.out.println(cache.get(8));       // returns -1 (not found)
//        cache.put(9, 22);
//        cache.put(5, 5);
//        cache.put(1, 30);
//
//        System.out.println(cache.get(11));       // returns -1
//        cache.put(9, 12);
//
//        System.out.println(cache.get(7));       // returns 4
//        System.out.println(cache.get(5));       // returns 4
//        System.out.println(cache.get(8));       // returns 4
//        System.out.println(cache.get(9));       // returns 4
//
//        cache.put(4, 30);
//        cache.put(9, 3);
//        System.out.println(cache.get(9));       // returns 4
//        System.out.println(cache.get(10));       // returns 4
//        System.out.println(cache.get(10));       // returns 4
//        cache.put(6, 14);
//        cache.put(3, 1);
//        System.out.println(cache.get(3));       // returns 4
    }
}

/**
 * Your LRUCache object will be instantiated and called as such:
 * LRUCache obj = new LRUCache(capacity);
 * int param_1 = obj.get(key);
 * obj.put(key,value);
 */