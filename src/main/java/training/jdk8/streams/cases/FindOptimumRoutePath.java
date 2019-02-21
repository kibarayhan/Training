package training.jdk8.streams.cases;

import java.util.Arrays;
import java.util.Map;
import java.util.Map.Entry;
import java.util.function.LongBinaryOperator;
import java.util.stream.Collectors;
import java.util.stream.LongStream;
import java.util.stream.Stream;

public class FindOptimumRoutePath {
	public static void main(String[] args) {
		String routes = "istanbul,12;Ankara,15;Kayseri,25;";

		Map<String, Long> route = Arrays.stream(routes.split(";")).map(str -> str.split(","))
				.collect(Collectors.toMap(str -> str[0], str -> Long.valueOf(str[1])));

		Stream<Entry<String, Long>> sorted = route.entrySet().stream().sorted(Map.Entry.comparingByValue());
		LongStream mapToLong = sorted.mapToLong(entry -> entry.getValue());

		mapToLong.reduce(0L, new LongBinaryOperator() {
			
			@Override
			public long applyAsLong(long left, long right) {
//				System.out.println("left:" + left + ", right:" + right);
//				System.out.println("diff:" + (right - left));
				System.out.print((right - left) + ",");
				return right;
			}
		});
		
		// .forEach((entry) -> System.out.println(entry.getKey() + "," + entry.getValue()));
//		route.forEach((k, v) -> System.out.println(k + ": " + v));
	}
}
