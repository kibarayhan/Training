package training.ds.queue;

import java.util.Arrays;

public class MyPriorityQueue {

	int[] items;
	int size;

	public static void main(String[] args) {
		MyPriorityQueue q = new MyPriorityQueue(10);
		q.add(15);
		q.printItems();

		q.add(20);
		q.printItems();

		q.add(6);
		q.printItems();

		q.add(28);
		q.printItems();
		q.remove();
		q.printItems();
	}

	public MyPriorityQueue(int maxSize) {
		items = new int[maxSize];
	}

	public boolean add(int item) {
		if (size == items.length)
			throw new IndexOutOfBoundsException();
		items[size] = item;

		int parent;

		for (int i = size; i > 0;) {
			parent = (i - 1) / 2;
			if (items[parent] >= items[i]) {
				break;
			}
			swapItems(parent, i);
			i = parent;
		}
		size++;
		return true;
	}

	public int remove() {
		if (size == 0)
			throw new IndexOutOfBoundsException();
		int returnVal = items[0];
		items[0] = items[size - 1];
		items[size - 1] = 0;

		for (int i = 0; i < size / 2;) {
			int left = 2 * i + 1;
			int right = left + 1;

			if (right < size && items[right] > items[left]) {
				if (items[right] <= items[i]) break;
				swapItems(i, right);
				i = right;
			}else {
				if (items[left] <= items[i]) break;
				swapItems(i, left);
				i = left;
			}
		}

		size--;
		return returnVal;
	}

	public boolean remove(int item) {
		return false;
	}

	public int peek() {
		return 0;
	}

	public void printItems() {
		System.out.println("-----------");
		Arrays.stream(items).forEach(i -> System.out.print(i + ","));
		System.out.println("");
	}

	private void swapItems(int i, int j) {
		int temp = items[i];
		items[i] = items[j];
		items[j] = temp;
	}
}
