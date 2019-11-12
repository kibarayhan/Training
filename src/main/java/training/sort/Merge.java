package training.sort;

import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;

public class Merge {

	private int[] merge(int[] a, int[] b) {
		int l = a.length - b.length - 1;
		int r = b.length - 1;
		int i = a.length - 1;

		while (r >= 0) {
			if (a[l] < b[r]) {
				a[i--] = b[r--];
			} else {
				a[i--] = a[l--];
			}
		}
		return a;
	}

	public static void main(String[] args) {
		List<String>[] list = ((ArrayList<String>[]) new ArrayList[10]); 
		ArrayList<Integer>[] al = new ArrayList[20];
		List<List<String>> listOfList = new ArrayList<>();
		
		
		int[] items = new Merge().merge(new int[] { 1, 3, 4, 0, 0 }, new int[] { 2, 5 });
 		printItems(items);
		items = new Merge().merge(new int[] { 1, 7, 8, 9, 0, 0, 0 }, new int[] { 2, 3, 4 });
		printItems(items);
	}

	static void printItems(int[] items) {
		Arrays.stream(items).forEach(i -> System.out.print(i + ","));
		System.out.println("");
	}

}
