package training.sort;

import org.junit.Assert;
import org.junit.Test;

public class SortTest {

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

	@Test
	public void whenSortedWithBubbleSort_thenGotSortedArray() {
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		BubbleSort bubbleSort = new BubbleSort();
		bubbleSort.bubbleSort(unsortedArray);

		Assert.assertArrayEquals(unsortedArray, sortedArray);
	}

	@Test
	public void whenSortedWithMergeSort_thenGotSortedArray(){
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		MergeSort mergeSort = new MergeSort();
		mergeSort.mergeSort(unsortedArray, unsortedArray.length);

		Assert.assertArrayEquals(unsortedArray, sortedArray);
	}

	@Test
	public void whenSortedWithQuickSort_thenGotSortedArray(){
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		QuickSort quickSort = new QuickSort();
		quickSort.quickSort(unsortedArray, 0, unsortedArray.length - 1);

		Assert.assertArrayEquals(unsortedArray, sortedArray);
	}


	@Test
	public void whenSortedWithHeapSortArrayImpl_thenGotSortedArray(){
		int[] unsortedArray = {2, 1, 4, 6, 3, 5};
		int[] sortedArray = {1,2,3,4,5,6};
		unsortedArray = HeapSortArrayImpl.sort(unsortedArray);

		Assert.assertArrayEquals(unsortedArray, sortedArray);

	}


}
