package training.sort;

import org.junit.Assert;
import org.junit.Test;

public class SortTest {

	@Test
	public void whenSortedWithBubbleSort_thenGotSortedArray() {
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		BubbleSort bubbleSort = new BubbleSort();
		bubbleSort.bubbleSort(unsortedArray);
		
		Assert.assertArrayEquals(unsortedArray, sortedArray);
	}
	
	
	@Test
	public void whenSortedWithSelectionSort_thenGotSortedArray() {
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		SelectionSort bubbleSort = new SelectionSort();
		bubbleSort.selectionSort(unsortedArray);
		
		Assert.assertArrayEquals(unsortedArray, sortedArray);
	}
	
	@Test
	public void whenSortedWithInsertionSortImperative_thenGotSortedArray() {
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		InsertionSort insertionSort = new InsertionSort();
		insertionSort.insertionSortImperative(unsortedArray);
		
		Assert.assertArrayEquals(unsortedArray, sortedArray);
	}

	@Test
	public void whenSortedWithInsertionSortRecursive_thenGotSortedArray() {
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		InsertionSort insertionSort = new InsertionSort();
		insertionSort.insertionSortRecursive(unsortedArray, unsortedArray.length);
		
		Assert.assertArrayEquals(unsortedArray, sortedArray);
	}

}
