package training.search;

import java.util.Arrays;
import java.util.Comparator;

public class AnagramComparator2 implements Comparator<String>{

	private String sort(String str) {
		char[] charArray = str.toCharArray();
		Arrays.sort(charArray);
		return new String(charArray);
	}
	
	@Override
	public int compare(String o1, String o2) {
		return sort(o1).compareTo(o2);
	}
	
	public static void main(String[] args) {
		String[] stringArray = {"ayhan", "ali", "lia", "nahya", "ial"};
		Arrays.sort(stringArray, new AnagramComparator2());
		printItems(stringArray);
	}
		
	static void printItems(String[] items) {
		Arrays.stream(items).forEach(i -> System.out.print(i + ","));
		System.out.println("");
	}

}
