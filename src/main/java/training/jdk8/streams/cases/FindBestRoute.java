package training.jdk8.streams.cases;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.function.BiConsumer;
import java.util.function.BiFunction;
import java.util.function.ObjLongConsumer;
import java.util.stream.Collectors;
import java.util.stream.LongStream;
import java.util.stream.Stream;

public class FindBestRoute {
    /**
     * Iterate through each line of input.
     */
    public static void main(String[] args) throws IOException {
//        InputStreamReader reader = new InputStreamReader(System.in, StandardCharsets.UTF_8);
//        BufferedReader in = new BufferedReader(reader);
//    String line = "Rkbs,5453; Wdqiz,1245; Rwds,3890; Ujma,5589; Tbzmo,1303;";
        String line = "Vgdfz,70; Mgknxpi,3958; Nsptghk,2626; Wuzp,2559; Jcdwi,3761;";
//    while ((line = in.readLine()) != null) {
        System.out.println(findRoute(line.split(";")));
//    }
    }

    private static String findRoute(String[] values) {
        Map<String, Long> route = Arrays.stream(values).map(s -> s.split(",", 2))
                .collect(Collectors.toMap(a -> a[0], a -> Long.valueOf(a[1])));

        Map<String, Long> sortedByValue = route.entrySet().stream().sorted(Map.Entry.comparingByValue())
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (e1, e2) -> e1, LinkedHashMap::new));               

        sortedByValue.values().forEach(System.out::println);

//		final Long [] arr = {0L};
//		final StringBuffer result = new StringBuffer();
//		sortedByValue.values().stream().forEach(t -> {			
//			result.append(t - arr[0]).append(",");
//			arr[0] = t;
//		});

        Long previousValue = 0L;
        StringBuffer result = new StringBuffer();
        for (Long value : sortedByValue.values()) {
            result.append(value - previousValue).append(",");
            previousValue = value;
        }

        return result.toString().substring(0, result.length() - 1);
    }
}