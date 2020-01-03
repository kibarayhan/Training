package training.ds.heap;

import java.lang.reflect.Array;
import java.util.*;

public class HeapProblems {

    public static void main(String[] args) {

    }

    private static class ArrayEntry{
        public int value, arrayIdx;
        public ArrayEntry(int value, int idx){
            this.arrayIdx = idx;
            this.value = value;
        }

        public int getValue(){
            return value;
        }
    }

    public static List<Integer> mergeSortedArrays(List<List<Integer>> sortedArrays){
        List<Iterator<Integer>> iters = new ArrayList<>(sortedArrays.size());
        PriorityQueue<ArrayEntry> heap = new PriorityQueue<>(Comparator.comparingInt(ArrayEntry::getValue));
        List<Integer> result = new ArrayList<>();

        for (List<Integer> sortedArray: sortedArrays){
            iters.add(sortedArray.iterator());
        }

        for (int i=0; i < iters.size() ; i++) {
            if (iters.get(i).hasNext()) heap.add(new ArrayEntry(iters.get(i).next(), i));
        }

        while (!heap.isEmpty()){
            ArrayEntry entry = heap.poll();
            result.add(entry.value);

            if (iters.get(entry.arrayIdx).hasNext()){
                heap.add(new ArrayEntry(iters.get(entry.arrayIdx).next(), entry.arrayIdx));
            }
        }

        return result;
    }

    //An array is said to be fc-increasing-decreasing if elements repeatedly increase up to a
    //certain index after which they decrease, then again increase, a total of k times
    public static List<Integer> sortAnIncreasingDecreasingArray(int[] array){

        return null;
    }
}
