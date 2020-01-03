package training.ds.array;

import java.util.*;

public class PlusOne {

    public static void main(String[] args) {
//        Arrays.stream(new PlusOne().plusOne(new int[]{9,9,9})).forEach(i -> System.out.print(i + ","));
        System.out.println(new PlusOne().simplifyPath("/home/a////b/c//"));

    }

    public String simplifyPath(String path) {
        Deque<String> stack = new LinkedList<>();

        for (String dir : path.split("/")){
            if (dir.equals("..") && !stack.isEmpty()){
                stack.pop();
            }else if (!dir.equals(".") && !dir.equals("") && !dir.equals("..")){
                stack.push(dir);
            }
        }
        if (stack.isEmpty()) return "/";

        String result = "";
        for(String dir : stack){
            result = "/" + dir + result;
        }

        return result;
    }

    public int[] plusOne(int[] digits) {
        for(int i=digits.length-1; i>=0; i--){
            if (digits[i]<9){
                digits[i]++;
                return digits;
            }
            digits[i] = 0;
        }
        digits = new int[digits.length + 1];
        digits[0] = 1;
        return digits;
    }
}
