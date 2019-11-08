package training.sort;

import java.util.Arrays;

/*
 * https://www.baeldung.com/java-insertion-sort 
 * Insertion sort is an efficient algorithm for small number of items. This method is based on the way 
 * card players sort a hand of playing cards. We start with an empty left hand and the cards laid down 
 * on the table. We then remove one card at a time from the table and insert it into the correct position 
 * in the left hand. To find the correct position for a new card, we compare it with the already sorted 
 * set of cards in the hand, from right to left.
 * 
 * The time taken by the INSERTION-SORT procedure to run is O(n^2). For each new item, we iterate from 
 * right to left over the already sorted portion of the array to find its correct position. Then we insert 
 * it by shifting the items one position to the right.
 * 
 * The algorithm sorts in place so its space complexity is O(1) for the imperative implementation 
 * and O(n) for the recursive implementation.
 */


public class InsertionSort {
	public static void main(String[] args) {		
		int items[] = new int[] {5, 7, 3, 9, 2};		
		//new InsertionSort().insertionSortImperative(items);
		
		new InsertionSort().insertionSortRecursive(items, items.length);
	}

	public void insertionSortImperative(int[] items) {
		System.out.print("- Init : ");
		printItems(items);
		int size = items.length;
		
		for (int i = 1; i < size; i++) {
			int value = items[i];
			int j = i - 1;
			while (j>=0 && value < items[j]) {
				items[j+1] = items[j];
				j = j -1;
			}
			items[j+1] = value;			
			System.out.print("-Iteration " + (i) + ": ");
			printItems(items);
		}
	}

	
	public void insertionSortRecursive(int[] items, int i) {
		if (i < 1)
			return;
		insertionSortRecursive(items, i-1);

		int value = items[i - 1];
		int j = i-2;		
		while (j>=0 && value < items[j]) {
			items[j+1] = items[j];
			j = j-1;
		}
		items[j+1] = value;		
	}
	
	
	void printItems(int[] items) {
		Arrays.stream(items).forEach(i -> System.out.print(i + ","));
		System.out.println("");
	}
	
	void swap(int items[], int i, int j) {
		int temp = items[j];
		items[j] = items[i];
		items[i] = temp;
	}
}
