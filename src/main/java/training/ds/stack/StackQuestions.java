package training.ds.stack;

import java.util.HashMap;
import java.util.Map;
import java.util.Stack;

public class StackQuestions {

    public static void main(String[] args) {
        StackQuestions test = new StackQuestions();
//        test.nextGreaterElement(new int[]{4,1,2}, new int[]{1,3,4,2});
        test.nextGreaterElementInCircularArray(new int[]{1,2,1});
    }

    private int[] nextGreaterElementInCircularArray(int[] nums) {
        int n = nums.length;
        int[] result = new int[n];
        Stack<Integer> stack = new Stack<>();

        for (int i = n*2-2; i >= 0; i--) {
            int cur = nums[i%n];

            while (!stack.isEmpty() && stack.peek() <= cur) {
                stack.pop();
            }

            if (stack.isEmpty()){
                result[i%n] =  -1;
                stack.push(cur);
            }else if (stack.peek() > cur){
                result[i%n] = stack.peek();
                stack.push(cur);
            }
        }

        for(int num : result){
            System.out.print(num + ",");
        }

        String s = "Sdsds";
        Stack<Character> stack2 = new Stack<>();
        for(Character c : s.toCharArray()){

        }


        return result;
    }


    public int[] nextGreaterElement(int[] nums1, int[] nums2) {
        int[] result = new int[nums1.length];
        Stack<Integer> stack = new Stack<>();
        Map<Integer, Integer> nextGreatMap = new HashMap<>();

        if (nums1.length == 0 || nums2.length == 0) {
            return result;
        }

        stack.push(nums2[0]);

        for (int i = 1; i < nums2.length; i++) {
            int cur = nums2[i];

            while (!stack.isEmpty() && stack.peek() < cur) {
                int x = stack.pop();
                nextGreatMap.put(x, cur);
            }
            stack.push(cur);
        }

        while (!stack.isEmpty()) {
            nextGreatMap.put(stack.pop(), -1);
        }

        for (HashMap.Entry<Integer, Integer> entry : nextGreatMap.entrySet()) {
            Integer k = entry.getKey();
            Integer v = entry.getValue();
            System.out.println("Key: " + k + ", Value: " + v);
        }

        for (int i = 0; i < nums1.length; i++) {
            result[i] = nextGreatMap.get(nums1[i]);
        }

        return result;
    }

}
