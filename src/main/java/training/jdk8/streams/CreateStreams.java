package training.jdk8.streams;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import java.util.stream.DoubleStream;
import java.util.stream.IntStream;
import java.util.stream.LongStream;
import java.util.stream.Stream;

public class CreateStreams {
	public static void main(String[] args) {
		// 1. Stream.of()
		Stream<String> aStream = Stream.of("ali", "veli", "kirk", "dokuz", "elli");
		aStream.forEach(System.out::println);

		//2. Stream.generate
		Stream.generate(Math::random).limit(10).forEach(System.out::println);
		
		//3. Stream.iterate
		List<BigDecimal> nums = 
				Stream.iterate(BigDecimal.ONE, t -> t.add(BigDecimal.ONE)).limit(10).collect(Collectors.toList());
		nums.forEach(System.out::println);
		
		//4. aList.stream
		List<String> aliVeli = Arrays.asList("ali", "veli", "kirk", "dokuz", "elli");
		aStream = aliVeli.stream();
		aStream.forEach(System.out::println);
		
		String[] aliVeliAsArray = {"ali", "veli", "kirk", "dokuz", "elli"};
		aStream = Arrays.stream(aliVeliAsArray);
		aStream.forEach(System.out::println);
		
		//5. range
		List<Integer> ints = IntStream.range(10, 15).boxed().collect(Collectors.toList());
		ints.forEach(System.out::println);

		List<Long> longs = LongStream.rangeClosed(10, 15).boxed().collect(Collectors.toList());
		longs.forEach(System.out::println);
	
	}
}
