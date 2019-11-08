package training.sort;

import java.util.Arrays;
import java.util.stream.IntStream;

/*
 * https://www.baeldung.com/java-bubble-sort
 * 
 * Bubble sort is sorting the unsorted array by comparing the item with its neighborhood and swapping (keep swapping adjacent elements)
 * if necessary (the item is bigger then its neighborhood) through iteration over an array. By each iteration
 * the  biggest value is placed to the end of array. The placed is excluded for further iterations. By this, 
 * it is guaranteed that the right part of array will be sorted.
 * 
 * Time complexity: Worst and Average case: O(n^2), when the array is in reverse order 
 * Best case: O(n), when the array is already sorted
 * The space complexity, even in the worst scenario, is O(1) as Bubble sort algorithm doesn't 
 * require any extra memory and the sorting takes place in the original array.
 */

public class BubbleSort {


	public static void main(String[] args) {
		int items[] = new int[] { 5, 7, 3, 9, 2 };
		new BubbleSort().bubbleSort(items);
		new BubbleSort().bubbleSortWithStreams(items);
	}

	public void bubbleSort(int[] items) {
		System.out.print("-Init		: ");
		printItems(items);
		int n = items.length;

		for (int i = 0; i < n - 1; i++) {
			boolean swapNeeded = false;
			for (int j = 0; j < n - 1 - i; j++) {
				if (items[j] > items[j+1]) {
					swap(items, j, j+1);
					swapNeeded = true;
				}
			}
			
			System.out.print("-Iteration" + (i + 1) + "	: ");
			printItems(items);
			
			if (!swapNeeded) // means already sorted
				break;
		}
	}

	public void bubbleSortWithStreams(int[] items) {
		int n = items.length;
		IntStream.range(0, n-1).flatMap( i -> IntStream.range(0, n-i-1)).forEach(j -> {
			if (items[j]> items[j+1] ) {
				swap(items, j, j+1);
			}
			printItems(items);
		});
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
