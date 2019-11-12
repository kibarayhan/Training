package training.search;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AnagramComparator1 {

	private Map<String, List<String>> aMap;
	private String[] array;
	
	public AnagramComparator1(String[] array) {
		aMap = new HashMap<>();
		this.array = array;
	}

	private String[] sort() {
		for (String str : array) {
			char[] charArray = str.toCharArray();
			Arrays.sort(charArray);
			String key = new String(charArray);
			List<String> aList = aMap.get(key);
			if (aList == null) {
				aList = new ArrayList<String>();
				aMap.put(key, aList);
			}
			
			aList.add(str);
		}
		
		int idx = 0;
		for (List<String> values : aMap.values()) {
			for (String strValue : values) {
				array[idx++] = strValue;
			}
		}
		return array;
	}
	
	public static void main(String[] args) {
		String[] stringArray = {"ayhan", "ali", "lia", "nahya", "ial"}; 		
		printItems(new AnagramComparator1(stringArray).sort());
	}
	
	
	static void printItems(String[] items) {
		Arrays.stream(items).forEach(i -> System.out.print(i + ","));
		System.out.println("");
	}
}
