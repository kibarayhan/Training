package training.ds.hash;

import java.util.ArrayList;
import java.util.List;

public class HashTableWithLinkedListImpl<K, V> implements HashTableI<K, V> {
    private List<LinkedHashEntry<K, V>> items;
    private float loadFactor = 0.75f;

    public HashTableWithLinkedListImpl(int size) {
        items = new ArrayList<>(size);
    }

    @Override
    public boolean put(K key, V value) {
        LinkedHashEntry<K, V> item = getItem(key);
        if (item != null) {
            item.value = value;
            return false;
        }

        int idx = getIndex(key);
        item = new LinkedHashEntry<K, V>(key, value);
        LinkedHashEntry<K, V> existingItem = items.get(idx);
        if (existingItem != null) {
            item.next = existingItem;
            existingItem.prev = item;
        }

        items.set(idx, item);
        return true;
    }

    @Override
    public V get(K key) {
        LinkedHashEntry<K, V> item = getItem(key);
        return item != null ? item.value : null;
    }

    @Override
    public V remove(K key) {
        V value = null;
        int idx = getIndex(key);
        LinkedHashEntry<K, V> item = items.get(idx);

        while (item != null) {
            if ((item.key == key) || (key!=null && key.equals(item.key))){
                value = item.value;
                if (item.prev != null) {
                    item.prev.next = item.next;
                }else{
                    // removing head, update
                    items.set(idx, item.next);
                }

                if (item.next != null){
                    item.next.prev = item.prev;
                }
                break;
            }
            item = item.next;
        }

        return value;
    }

    private LinkedHashEntry<K, V> getItem(K key) {
        int idx = getIndex(key);
        LinkedHashEntry<K, V> item = items.get(idx);
        while (item != null) {
            if ((item.key == key) || (key!=null && key.equals(item.key))) {
                return item;
            }
            item = item.next;
        }
        return null;
    }

    private int getIndex(K key) {
        int result = 1;
        result = result * 31 + (key == null ? 0 : key.hashCode());
        result = result & 0x7FFFFFFF;
        return result % items.size();
    }

    private static class LinkedHashEntry<K, V> {
        K key;
        V value;
        LinkedHashEntry<K, V> prev;
        LinkedHashEntry<K, V> next;

        LinkedHashEntry(K key, V value) {
            this.key = key;
            this.value = value;
        }

    }
}
