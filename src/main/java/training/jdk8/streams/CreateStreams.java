package training.jdk8.streams;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.function.Function;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import java.util.stream.DoubleStream;
import java.util.stream.IntStream;
import java.util.stream.LongStream;
import java.util.stream.Stream;

public class CreateStreams {
    public static void main(String[] args) {
        // 1. Stream.of()
        System.out.println("1. Creating streams with Stream.of(T... values):");
        String names = Stream.of("ali", "veli", "kirk", "dokuz", "elli").collect(Collectors.joining(","));
        System.out.println(names);

        //2. Stream.iterate
        System.out.println("\n2. Creating streams with Stream.iterate(final T seed, final UnaryOperator<T> f):");
        List<BigDecimal> nums = Stream.iterate(BigDecimal.ONE, t -> t.add(BigDecimal.ONE)).limit(10).collect(Collectors.toList());
        System.out.println(nums);

        Stream.iterate(LocalDate.now(), d -> d.plusMonths(1)).limit(12).forEach(System.out::println);

        //3. Stream.generate
        System.out.println("\n3. Creating Stream with Stream.generate(Supplier<T> s):");
        Stream.generate(Math::random).limit(10).forEach(System.out::println);
        DoubleSummaryStatistics stats = DoubleStream.generate(Math::random).limit(1_000_000).summaryStatistics();
        System.out.println(stats);

        //4. aList.stream()
        System.out.println("\n4. Creating Stream with aList.stream():");
        List<String> aliVeliList = Arrays.asList("ali", "veli", "kirk", "dokuz", "elli");
        names = aliVeliList.stream().collect(Collectors.joining(","));
        System.out.println(names);

        // 5. Arrays.stream()
        System.out.println("\n5.Creating Stream with Arrays.stream(T[] array):");
        String[] aliVeliAsArray = {"ali", "veli", "kirk", "dokuz", "elli"};
        names = Arrays.stream(aliVeliAsArray).collect(Collectors.joining(","));
        System.out.println(names);

        //6. range or rangeClosed
        System.out.println("\n6.1. Creating Stream with IntStream.range(int startInclusive, int endExclusive):");
        List<Integer> ints = IntStream.range(10, 15)
//				.mapToObj(Integer::valueOf)
                .boxed()
                .collect(Collectors.toList());
        System.out.println(ints);

        System.out.println("\n6.2. Creating Stream with LongStream.rangeClosed(long startInclusive, final long endInclusive):");
        List<Long> longs = LongStream.rangeClosed(10, 15)
				.boxed()
				.collect(Collectors.toList());
        System.out.println(longs);

        System.out.println("\n7. Creating a HashMap from a list");
        Map<String, Integer> lengthOfStrings = Stream.of("this", "is", "a list", "of", "some", "strings")
                .collect(Collectors.toMap(t -> t, String::length));
        lengthOfStrings.forEach( (word, length) -> System.out.printf("a length of the '%s' is %d %n", word, length));

        Map<String, Integer> lengthOfStringsOrdered =
                lengthOfStrings.entrySet().stream().sorted(Map.Entry.comparingByKey(Comparator.reverseOrder())).collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

		System.out.println("\n");
		Map<String, Long> countOfStrings = Stream.of("this", "is", "this", "of", "of", "strings").collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));
		countOfStrings.forEach( (word, count) -> System.out.printf("the '%s' count is %d %n", word, count));
    }
}
