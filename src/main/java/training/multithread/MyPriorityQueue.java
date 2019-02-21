package training.multithread;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Optional;
import java.util.Queue;

public class MyPriorityQueue{

	List<Item> items;
	private static Object lock = new Object();
	int size;
	
	public MyPriorityQueue(int size) {
		items = new ArrayList<Item>(size);
	}

	public MyPriorityQueue() {
		items = new ArrayList<Item>();
	}
	
	class Item{
		int priority;
		int age;
		
		public Item(int priority, int age) {
			this.priority = priority;
			this.age = age;
		}
	}


	public int size() {
		return items.size();
	}

	public boolean isEmpty() {
		return items.isEmpty();
	}

	public boolean contains(Object o) {
		return items.contains(o);
	}

	public Iterator<Item> iterator() {
		return items.iterator();
	}

	public boolean remove(Object o) {
		return false;
	}

	public void clear() {
		// TODO Auto-generated method stub
	}

	public boolean add(Object e) {
		Item item = (Item) e;
		boolean added = false;
		synchronized(lock) {
			items.add(item);
			lock.notify();
		}
		return added;
	}

	public Object remove() {
		while (true) {
			synchronized (lock) {
				if (items.isEmpty()) {
					try {
						lock.wait();
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
				}else {
					Optional<Item> itemToRemove = items.stream().sorted(new Comparator<Item>() {
						@Override
						public int compare(Item o1, Item o2) {
							if (o1.priority > o2.priority) {
								return -1;
							}else if (o1.priority < o2.priority) {
								return 1;
							}
							if (o1.age > o2.age) {
								return -1;
							}else if (o1.age < o2.age) {
								return 1;
							}
							return 0;
						}
					}).findFirst();
					
					if (itemToRemove.isPresent()) {
						items.remove(itemToRemove.get());
						return itemToRemove.get();
					}
					
					return null;
				}
			}
		}
	}

	public Object poll() {
		// TODO Auto-generated method stub
		return null;
	}

	public Object peek() {
		// TODO Auto-generated method stub
		return null;
	}
}
