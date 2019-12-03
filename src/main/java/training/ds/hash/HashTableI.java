package training.ds.hash;

public interface HashTableI<K, V> {

    public boolean put(K key, V value);
    public V remove(K key);
    public V get(K key);
}
