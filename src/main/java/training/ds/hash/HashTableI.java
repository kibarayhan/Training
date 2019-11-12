package training.ds.hash;

public interface HashTableI<K, V> {

    public boolean add(K key, V value);
    public V get(K key);
    public V remove(K key);
}
