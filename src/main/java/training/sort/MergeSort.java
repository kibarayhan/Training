package training.sort;

import java.util.Arrays;

/*
https://www.baeldung.com/java-merge-sort
Merge sort is a "divide and conquer" algorithm where you dive the problem into sub-problems and first try to solve this
sub-problems. When the sub-problems are solved we combine them together to get the final solution to the problem.
Divide: In this step, we divide the input array into 2 halves, the pivot being the midpoint of the array.
This step is carried out recursively for all the half arrays until there are no more half arrays to divide.
Conquer: In this step, we sort and merge the divided arrays from bottom to top and get the sorted array.

As merge sort is a recursive algorithm,  the time complexity can be expressed as the following recursive relation:
T(n) = 2T(n/2) + O(n)
2T(n/2) corresponds to the time required to sort the sub-arrays and O(n) time to merge the entire array.
When solved, the time complexity will come to O(nLogn).

This is true for the worst, average and best case since it will always divide the array into two and then merge.
The space complexity of the algorithm is O(n) as we're creating temporary arrays in every recursive call.
 */
public class MergeSort {

	public static void main(String[] args) {
		int[] items = {5, 7, 3, 9, 2};
		new MergeSort().mergeSort(items, items.length);
		printItems(items);
	}

	public void mergeSort(int[] items, int n) {
		if (n<2) return;
		
		int mid = n/2;
		int[] left = new int[mid];
		int[] right = new int[n - mid];
		
		for (int i = 0; i < mid; i++) {
			left[i] = items[i];
		}

		for (int i = mid; i < n; i++) {
			right[i-mid] = items[i];
		}

		mergeSort(left, mid);
		mergeSort(right, n - mid);
		
		merge(items, left, right);
	}

	private void merge(int[] items, int[] left, int[] right) {
		int i = 0, j = 0, k =0;
		
		while (i < left.length && j < right.length){
			if (left[i] <= right[j]) {
				items[k++] = left[i++];
			}else {
				items[k++] = right[j++];
			}
		}

		while (i < left.length){
			items[k++] = left[i++];
		}

		while (j < right.length){
			items[k++] = right[j++];
		}
	}

	static void printItems(int[] items) {
		Arrays.stream(items).forEach(i -> System.out.print(i + ","));
		System.out.println("");
	}
}
