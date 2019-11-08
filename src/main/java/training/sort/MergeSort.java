package training.sort;

public class MergeSort {

	public static void main(String[] args) {
		int[] items = {5, 7, 3, 9, 2};
		new MergeSort().mergeSort(items, items.length);
	}

	private void mergeSort(int[] items, int n) {
		if (n<2) return;
		
		int mid = n/2;
		int[] left = new int[mid];
		int[] right = new int[n - mid];
		
		for (int i = 0; i < mid; i++) {
			left[i] = items[i];
		}

		for (int i = mid; i < n; i++) {
			left[i-mid] = items[i];
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
}
