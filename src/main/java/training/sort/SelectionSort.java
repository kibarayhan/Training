package training.sort;

import java.util.Arrays;

/*
 * 	https://www.baeldung.com/java-selection-sort
 * 	Selection sort is sorting an unsorted array by finding the minimum element and place it to the
 *  most appropriate left place of the array where this place index is increasing by each iteration.
 *  For the first iteration this is the 1st, for second iteration this is the 2nd place.
 *  
 *  Time complexity of O(n^2).
 *  Selection Sort requires one extra variable to hold the value temporarily for swapping. Therefore, 
 *  Selection Sort's space complexity is O(1)
 */

public class SelectionSort {

	public static void main(String[] args) {		
		int items[] = new int[] {5, 7, 3, 9, 2};		
		new SelectionSort().selectionSort(items);
	}

	public void selectionSort(int[] items) {
		System.out.print("- Init : ");
		printItems(items);
		int size = items.length;
		
		for (int i = 0; i < size - 1; i++) {
			int min = i;
			for (int j = i + 1; j < size; j++) {
				if (items[min] > items[j])
					min = j;
			}
			
			System.out.print("-Iteration " + (i+1) + ": ");
			swap(items, min, i);
			printItems(items);
		}
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
