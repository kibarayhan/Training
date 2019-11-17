package training.jdk8.streams.cases;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

public class FindMinimumValue {
	/**
	 * Iterate through each line of input.
	 */
	public static void main(String[] args) throws IOException {
		InputStreamReader reader = new InputStreamReader(System.in, StandardCharsets.UTF_8);
		BufferedReader in = new BufferedReader(reader);
		String line;
		while ((line = in.readLine()) != null) {
			List<String> asList = Arrays.asList(line.split(" "));
			System.out.println(findMin(asList));
		}
	}

	private static int findMin(List<String> values) {
		Map<String, Long> groupValuesByCount = values.stream()
				.collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));
		Optional<String> uniqueValue = groupValuesByCount.entrySet().stream().filter(e -> e.getValue() == 1L).findFirst()
				.map(Map.Entry::getKey);

		if (uniqueValue.isPresent()) {
			return values.indexOf(uniqueValue.get()) + 1;
		}
		
		return 0;
	}
}