package training.sort;

import java.util.Arrays;

/*
https://www.baeldung.com/java-quicksort
Quicksort is a sorting algorithm, which is leveraging the divide-and-conquer principle.
It has an average O(n log n) complexity and it&rsquo;s one of the most used sorting algorithms, especially for big data volumes.

It's important to remember that Quicksort isn't a stable algorithm. A stable sorting algorithm is an algorithm where
the elements with the same values appear in the same order in the sorted output as they appear in the input list.

Algorithm steps:
1. We choose an element from the list, called the pivot. We'll use it to divide the list into two sub-lists.
2. We reorder all the elements around the pivot &ndash; the ones with smaller value are placed before it, and all the elements
greater than the pivot after it. After this step, the pivot is in its final position. This is the important partition step.
3. We apply the above steps recursively to both sub-lists on the left and right of the pivot.\

The crucial point in QuickSort is to choose the best pivot. The middle element is, of course, the best, as it would
divide the list into two equal sub-lists.

n the best case, the algorithm will divide the list into two equal size sub-lists. So, the first iteration of the full
n-sized list needs O(n). Sorting the remaining two sub-lists with n/2 elements takes 2*O(n/2) each. As a result, the
QuickSort algorithm has the complexity of O(n log n).
In the worst case, the algorithm will select only one element in each iteration, so O(n) + O(n-1) + &hellip; + O(1), which is
equal to O(n2).
On the average QuickSort has O(n log n) complexity, making it suitable for big data volumes.
It has an O(log(n)) space complexity and It&rsquo;s generally an &ldquo;in-place&rdquo; algorithm.

Although both Quicksort and Mergesort have an average time complexity of O(n log n), Quicksort is the preferred algorithm,
as it has an O(log(n)) space complexity. Mergesort, on the other hand, requires O(n) extra storage, which makes it quite
expensive for arrays.

Quicksort requires to access different indices for its operations, but this access is not directly possible in linked
lists, as there are no continuous blocks; therefore to access an element we have to iterate through each node from the
 beginning of the linked list. Also, Mergesort is implemented without extra space for LinkedLists.
In such case, overhead increases for Quicksort and Mergesort is generally preferred for LinkedLists.
 */
public class QuickSort {

    public static void main(String[] args) {
        int items[] = {5, 7, 3, 9, 6};
        new QuickSort().quickSort(items, 0, items.length -1 );
        printItems(items);
    }

    public void quickSort(int[] items, int begin, int end) {
        if (begin < end) {
            int partitionIndex = partition(items, begin, end);
            quickSort(items, begin, partitionIndex-1);
            quickSort(items, partitionIndex+1, end);
        }
    }

    /*
    checks each element and swaps it before the pivot if its value is smaller or equal.
    By the end of the partitioning, all elements less then the pivot are on the left of it and all elements greater
    then the pivot are on the right of it. The pivot is at its final sorted position and the function returns this position
     */
    private int partition(int[] items, int begin, int end) {
        int pivot = items[end];
        int i = (begin -1);

        for (int j = begin; j < end; j++){
            if (items[j] <= pivot){
                i++;
                swap(items, i, j);
            }
        }
        swap(items, i+1, end);
        return i+1;
    }


    static void printItems(int[] items) {
        Arrays.stream(items).forEach(i -> System.out.print(i + ","));
        System.out.println("");
    }

    static void swap(int items[], int i, int j) {
        int temp = items[j];
        items[j] = items[i];
        items[i] = temp;
    }

}
