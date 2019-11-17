package training.hackerrank;

public class ArrayManipulation {

	// Complete the arrayManipulation function below.
	static long arrayManipulation(int n, int[][] queries) {
		int[] arr = new int[n];
		int max = 0;

		for (int i = 0; i < queries.length; i++) {
			int idx1 = queries[i][0] - 1;
			int idx2 = queries[i][1] - 1;
			int val = queries[i][2];
			for (int j = idx1; j <= idx2; j++) {
				arr[j] += val;
				if (arr[j] > max) {
					max = arr[j];
				}
			}
		}
		return max;
	}

	public static void main(String[] args) {
		int[][] queries = new int[][] { { 1, 2, 100 }, { 2, 5, 100 }, { 3, 4, 100 } };

		long result = arrayManipulation(5, queries);
		System.err.println(result);
	}
}
