package training.search;

public class BinarySearch {

	public int binarySearchImperative(int[] items, int item) {
		int low = 0;
		int high = items.length - 1;
		int mid;

		while (low <= high) {
			mid = (low + high) / 2;
			if (item < items[mid]) {
				high = mid - 1;
			} else if (item > items[mid]) {
				low = mid + 1;
			} else {
				return mid;
			}
		}
		return -1;
	}

	public int binarySearchRecursive(int[] items, int item, int low, int high) {
		if (low > high)
			return -1;

		int mid = (low + high) / 2;
		if (item < items[mid]) {
			return binarySearchRecursive(items, item, low, mid - 1);
		} else if (item > items[mid]) {
			return binarySearchRecursive(items, item, mid + 1, high);
		}else {
			return mid;
		}
	}
	
	public static void main(String[] args) {
		int[] items = new int[] { 1, 2, 3 };
		// int idx = new BinarySearch().binarySearchImperative(items, 1);
		int idx2 = new BinarySearch().binarySearchRecursive(items, 1, 0, 2);
		System.out.println(String.format("%d", idx2));
		// System.out.println(String.format("%d, %d", idx, idx2));
	}

}
