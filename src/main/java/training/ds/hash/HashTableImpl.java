package training.ds.hash;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class HashTableImpl<K,V> implements HashTableI<K,V> {
	
	private int size;
	private int numElements;
	private float maxLoadFactor;
	private List<HashEntry<K,V>>[] items;

	public HashTableImpl(int size) {
		super();
		this.size = size;
		this.numElements = 0;
		this.maxLoadFactor = 0.75f;
		items = new ArrayList[size];
		Arrays.fill(items, new ArrayList<>());
	}

	@Override
	public boolean put(K key, V value) {
		if (loadFactor() > maxLoadFactor) {
			resize(size*2 + 1);
		}
		HashEntry<K,V> item = getItem(key);
		if (item != null){
			item.value = value;
			return false;
		}

		items[getIndex(key)].add(new HashEntry<>(key, value));
		numElements++;
		return true;
	}

	@Override
	public V get(K key) {
		HashEntry<K,V> item = getItem(key);
		return item != null? item.value : null;
	}
	
	@Override
	public V remove(K key) {
		HashEntry<K,V> item = getItem(key);
		if (item != null) {
			items[getIndex(key)].remove(item);
			numElements--;
			return item.value;
		}
		return null;
	}

	private int getIndex(K key) {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((key == null) ? 0 : key.hashCode());
		result = result & 0x7FFFFFFF; // remove the sign bit or convert it to positive (32 bit int)
		result = result % size;
		return result;
	}

	private HashEntry<K,V> getItem(K key) {
		int idx = getIndex(key);
		for (HashEntry<K,V> item : items[idx]){
			if (item.key == key || (key!=null && key.equals(item.key))) {
				return item;
			}
		}
		return null;
	}


	private void resize(int i) {
		// TODO Auto-generated method stub
	}	
	
	private float loadFactor() {
		return (float) (numElements / size);
	}

	private static class HashEntry<K,V>{
		K key;
		V value;
		
		HashEntry(K key, V value) {
			super();
			this.key = key;
			this.value = value;
		}
	}

}
