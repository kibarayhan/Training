package training.ds.stack;

import java.util.BitSet;
import java.util.Stack;
import java.util.function.IntPredicate;
import java.util.function.Predicate;
import java.util.stream.IntStream;

public class Test {

	public static void main(String[] args) {
		System.out.println(longestValidParentheses(")()())"));
	}

	public static int longestValidParentheses(String s) {
		Stack<Integer> stIdx = new Stack<>();
		Stack<Character> stChar = new Stack<>();
		int result = 0;
		for(int i = 0; i < s.length(); i++){
			if (s.charAt(i) == '(' ){
				stChar.push(s.charAt(i));
				stIdx.push(i);
			}else{
				if (!stChar.isEmpty() && stChar.peek() == '('){
					stChar.pop();
					stIdx.pop();
				}else{
					stIdx.push(i);
				}
			}
		}

		if (stIdx.isEmpty()) return s.length();
		else{
			int a = s.length(), b=0;
			while(!stIdx.isEmpty()){
				b = stIdx.pop();
				result = Math.max(result, a-b-1);
				a = b;
			}
			return Math.max(result, a);
		}
	}

}
