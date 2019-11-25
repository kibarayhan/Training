package training.search;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class AnagramComparator1 {

    private String[] sort(String[] array) {
        Map<String, List<String>> aMap = new HashMap<>();
        for (String str : array) {
            char[] charArray = str.toCharArray();
            Arrays.sort(charArray);
            String key = new String(charArray);
            List<String> aList = aMap.computeIfAbsent(key, k -> new ArrayList<>());
//			List<String> aList = aMap.get(key);
//			if (aList == null) {
//				aList = new ArrayList<String>();
//				aMap.put(key, aList);
//			}
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

    private String[] sortUsingStreams(String[] stringArray) {
//		Map<String, List<String>> anagramMap = Arrays.stream(stringArray).collect(Collectors.groupingBy(s -> {
//			char[] chars = s.toCharArray();
//			Arrays.sort(chars);
//			return new String(chars);
//		}, Collectors.mapping(s -> s, Collectors.toList())));

        Map<String, List<String>> anagramMap = Arrays.stream(stringArray).collect(Collectors.groupingBy(s -> {
            char[] chars = s.toCharArray();
            Arrays.sort(chars);
            return new String(chars);
        }));

		// this is full result of joining
//		return anagramMap.values().stream().map(s -> String.join(",", s)).toArray(String[]::new);
//		return anagramMap.values().stream().map(s -> s.stream().collect(Collectors.joining(","))).toArray(String[]::new);
        
        // this is filtered (only anagrams) result of joining
        return anagramMap.values().stream()
        		.filter(s -> s.size() > 1) // filter by size of values collected that are considered as anagram
        		.sorted(Comparator.comparingInt(s -> s.get(0).length())) // sorted by length
				.flatMap(s -> s.stream()) // use flatMap to convert values to streams which are flattened to a single stream later on
        		//.map(s -> String.join(",", s)) // joining the values collected that are considered as anagram by ","
        		.toArray(String[]::new); // converting to array
    }


    public static void main(String[] args) {
        String[] stringArray = {"ayhan", "ali", "lia", "nahya", "ial", "asdad"};
        printItems(new AnagramComparator1().sort(stringArray));
        printItems(new AnagramComparator1().sortUsingStreams(stringArray));

    }

    private static void printItems(String[] items) {
        Arrays.stream(items).forEach(i -> System.out.print(i + ";"));
        System.out.println("");
    }
}
