package training.jdk8.streams.cases;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.function.IntPredicate;
import java.util.stream.Collectors;

public class FindMinUniqueNumber {

	public static void main(String[] args) {
		String input = "1,3,3,3,1,5,6,5,6,7,8,4";
		IntPredicate lessThan10 = (i) -> (0 < i && i < 10);
		List<String> list1 = Arrays.asList(input.split(","));

//		Map<Integer, Long> numbers = list1.stream()
//			.mapToInt(s -> Integer.valueOf(s))
//			.filter( lessThan10).boxed()
//			.reduce(new HashMap<Integer, Long>(), (map, number) -> {
//				if (! map.containsKey(number)) {
//					map.put(number, 1L);
//				}else {
//					map.put(number, map.get(number) + 1L);
//				}
//				return map;
//			}, (map1, map2) -> {
//				map1.putAll(map2);
//				return map1;
//			});

		Map<Integer, Long> counted = list1.stream().mapToInt(s -> Integer.valueOf(s)).filter(lessThan10).boxed()
				.collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));

		counted.forEach((k, v) -> System.out.println(k + ": " + v));

//		Optional<Map.Entry<Integer, Long>> unique = counted.entrySet().stream()
//				.filter(set -> set.getValue() ==1 ).
//				sorted(new Comparator<Map.Entry<Integer, Long>>() {
//					@Override
//					public int compare(Entry<Integer, Long> o1, Entry<Integer, Long> o2) {
//						return o1.getKey() - o2.getKey();
//					}
//				}).findFirst();

		Optional<Map.Entry<Integer, Long>> unique = counted.entrySet().stream().filter(entry -> entry.getValue() == 1)
				.sorted(Map.Entry.comparingByKey()).findFirst();

		if (unique.isPresent()) {
			String key = unique.get().getKey().toString();
			System.out.println(key + ":" + (list1.indexOf(key) + 1));
		} else {
			System.out.println(0);
		}
	}
}
