package training.sort;

import java.util.Arrays;
import java.util.stream.Collectors;

public class HeapSortImpl {

    public static void main(String[] args) {
        int[] array = new int[]{1, 4, 80, 20, 60, 10, 5, 8, 15, 55, 70};
        HeapSortImpl heapSort = new HeapSortImpl();
        int[] sortedArray = heapSort.heapSort(array);

        String result = Arrays.stream(sortedArray).boxed().map(i -> Integer.toString(i)).collect(Collectors.joining(","));
        System.out.println("result = " + result);
        //Arrays.stream(sortedArray).forEach(c -> System.out.println(c +","));
    }

    private int[] heapSort(int[] array) {
        int n = array.length;

        for(int i = (n/2) - 1; i>=0; i--){
            array = heapifyMax(array, i);
            String result = Arrays.stream(array).boxed().map(s -> Integer.toString(s)).collect(Collectors.joining(","));
            System.out.println("result = " + result + ". for parent" + (i+1));

        }

        return array;
    }

    private int[] heapifyMax(int[] array, int i) {
        while (i < array.length/2){
            int left = 2*i + 1;
            int right = 2*i + 2;

            if (array[right] > array[left]){
                if (array[right] <= array[i]) break;
                swap(array, i, right);
                i = right;
            }else{
                if (array[left] <= array[i]) break;
                swap(array, i, left);
                i = left;
            }
        }
        return array;
    }

    private void swap(int[] array, int i, int j) {
        int temp = array[j];
        array[j] = array[i];
        array[i] = temp;
    }
}
