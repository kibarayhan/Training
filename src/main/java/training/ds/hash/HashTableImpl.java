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
	public boolean add(K key, V value) {
		if (loadFactor() > maxLoadFactor) {
			resize(size*2 + 1);
		}
		
		items[key.hashCode()].add(new HashEntry<>(key, value));
		numElements++;
		return true;
	}

	@Override
	public V get(K key) {
		for (HashEntry<K, V> p : items[key.hashCode()]) {
			if (((Comparable) key).compareTo(p.key)==0) {
				return p.value;
			}
		}

		return null;
	}
	
	@Override
	public V remove(K key) {
		HashEntry<K, V> node  = null;
		
		for (HashEntry<K, V> p : items[key.hashCode()]) {
			if (((Comparable) key).compareTo(p.key)==0) {
				node = new HashEntry<K, V>(key, p.value);				
				break;
			}
		}
		
		if (node != null) {
			items[key.hashCode()].remove(node);
			numElements--;
			return node.value;			
		}
		return null;
	}

	private void resize(int i) {
		// TODO Auto-generated method stub
	}	
	
	private float loadFactor() {
		return (float) (numElements / size);
	}

	class HashEntry<K,V> implements Comparable<HashEntry<K,V>>{
		K key;
		V value;
		
		public HashEntry(K key, V value) {
			super();
			this.key = key;
			this.value = value;
		}

		@Override
		public int compareTo(HashEntry<K,V> o) {
			return ((Comparable<K>)this.key).compareTo(o.key);
		}

		@Override
		public int hashCode() {
			final int prime = 31;
			int result = 1;
			result = prime * result + ((key == null) ? 0 : key.hashCode());
			result = result & 0x7FFFFFFF; // remove the sign bit or convert it to positive (32 bit int)
			result = result % size;
			return result;
		}

		@Override
		public boolean equals(Object o) {
			if (this == o)
				return true;
			if (o == null)
				return false;
			if (getClass() != o.getClass())
				return false;
			HashEntry<?, ?> other = (HashEntry<?, ?>) o;			
			if (key == null) {
				if (other.key != null)
					return false;
			} else if (!key.equals(other.key))
				return false;
			return true;
		}		
		
	}

}
