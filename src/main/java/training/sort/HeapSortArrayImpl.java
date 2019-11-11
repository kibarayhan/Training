package training.sort;

import java.util.Arrays;
/*
https://www.baeldung.com/java-heap-sort
https://www.youtube.com/watch?v=LbB357_RwlY

Heap Sort is based on the Heap data structure. A Heap is a specialized tree-based data structure.
For Max-Heap:
   - every node's value must be more or equal to all values stored in its children
   - it's a complete tree, which means it has the least possible height
Because of the 1st rule, the biggest element always will be in the root of the tree.

these are the steps for Heap sort:
1. Generate heap, by adding each element from the array to the heap. Add function should produce heap. O(n logn)
logn for heapify operation, since heap structure max iteration will be the size of level of heap and it is logn.
2. Until heap is empty pop the element from heap. Pop returns the root (0th index) element which is the
biggest for max-heap, this is done by swapping 0th and n-1th index of the heap, after that heap size is reduced by 1.
This is also O(n logn).
Overall complexity is O(n logn).
Below algorithm works as in place by checking the left and right child indexes by size of heap

lso worth mentioning, that 50% of the elements are leaves, and 75% of elements are at the two bottommost levels.
Therefore, most insert operations won't take more, than two steps.
Note, that on real-world data, Quicksort is usually more performant than Heap Sort. The
silver lining is that Heap Sort always has a worst-case O(n log n) time complexity..
 */

public class HeapSortArrayImpl {
    int[] items;
    int size;
    int maxSize;

    public HeapSortArrayImpl(int length) {
        this.items = new int[length];
        this.maxSize = length;
    }

    public static int[] sort(int[] array) {
        HeapSortArrayImpl heapSortArray = new HeapSortArrayImpl(array.length);
        heapSortArray.buildHeap(array);

        while (!heapSortArray.isEmpty()) {
            heapSortArray.pop();
        }

        return heapSortArray.items;
    }

    public boolean isEmpty() {
        return size <= 0;
    }

    private void buildHeap(int[] array) {
        for (int i = 0; i < array.length; i++) {
            add(array[i]);
        }
    }

    public void add(int value) {
        if (size >= maxSize)
            throw new IndexOutOfBoundsException("heap is full!");
        this.items[size] = value;
        int index = size;
        while (index > 0) {
            int parentIndex = getParentIndex(index);
            if (this.items[parentIndex] < this.items[index]) {
                swap(this.items, parentIndex, index);
            }
            index = parentIndex;
        }
        size++;
    }


    public int pop() {
        if (size == 0)
            throw new IndexOutOfBoundsException("heap is empty!");

        int max = this.items[0];
        this.items[0] = this.items[size - 1];
        this.items[size - 1] = max;

        int index = 0;
        while (index < (size / 2) ) {
            int left = getLeftChildIndex(index);
            int right = getRightChildIndex(index);

            if (right < (size-1) && items[right] > items[left]) {
                if (items[right] <= items[index]) break;
                swap(this.items, index, right);
                index = right;
            }else{
                if (left >= size-1 || items[left] <= items[index]) break;
                swap(this.items, index, left);
                index = left;
            }
        }
        size--;
        return max;
    }

    public int getParentIndex(int index) {
        return (index - 1) / 2;
    }

    public int getLeftChildIndex(int index) {
        return 2 * index + 1;
    }

    public int getRightChildIndex(int index) {
        return 2 * (index + 1);
    }

    private void swap(int[] array, int i, int j) {
        int temp = array[j];
        array[j] = array[i];
        array[i] = temp;
    }

    public static void printItems(int[] items) {
        Arrays.stream(items).forEach(i -> System.out.print(i + ","));
        System.out.println("");
    }


    public static void main(String[] args) {
        int[] items = {5, 7, 3, 9, 6};
        int[] sortedArray = HeapSortArrayImpl.sort(items);
        printItems(sortedArray);

    }

}
