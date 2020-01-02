package training.jdk8.streams.cases;

import java.util.*;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class HotelRating {
    private static final Pattern DELIMITER = Pattern.compile(" ");

    private static <K, V> void printMap(Map<K, V> map) {
        map.forEach((k, v) -> System.out.println(k + ": " + v));
        System.err.println("--------------------------------------");
    }

    public String[] getMostRatedHotel(List<String> positiveWords, List<String> negativeWords, List<String> hotels, List<String> comments) {
        int idx = 0;

        Map<String, Long> hotelMapByPoints = new HashMap<>();
        for (String comment : comments) {
            String[] arr = comment.split(" ");
//          Map<String, Long> commentRank = Arrays.stream(comment.split(" ")).collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));    		
            Map<String, Long> commentRank = DELIMITER.splitAsStream(comment).collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));
            Long pozitivePoints = positiveWords.stream().mapToLong(s -> commentRank.get(s) != null ? commentRank.get(s) * 3 : 0).sum();
            Long negativePoints = negativeWords.stream().mapToLong(s -> commentRank.get(s) != null ? commentRank.get(s) : 0).sum();
            hotelMapByPoints.put(hotels.get(idx++), pozitivePoints - negativePoints);
        }

        Map<String, Long> map2 = hotelMapByPoints.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (e1, e2) -> e1, LinkedHashMap::new));

        printMap(map2);

        hotelMapByPoints = hotelMapByPoints.entrySet().stream()
//                .filter(e -> e.getValue()>5)
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        Map.Entry::getValue,
                        (e1, e2) -> e1,
                        LinkedHashMap::new));

        printMap(hotelMapByPoints);
        return null;
    }

    public Double average(List<Integer> list) {
        OptionalDouble avg = list.stream()
                .mapToInt(i -> i)
                .average();
        return avg.orElseGet(() -> (double) 0);
    }

    public List<String> upperCase(List<String> list) {
        return list.stream().map(String::toUpperCase).collect(Collectors.toList());
    }

    public List<String> search(List<String> list) {
        return list.stream()
                .filter(s -> s.length() == 3 && s.startsWith("a"))
                .collect(Collectors.toList());
    }

    //Write a method that returns a comma separated string based on a given list of integers. Each element should be
    // preceded by the letter 'e' if the number is even, and preceded by the letter 'o' if the number is odd. For
    // example, if the input list is (3,44), the output should be 'o3,e44'.
    public String getString(List<Integer> list) {
        int $asdasd;
        return list.stream()
                .map(i -> i % 2 == 0 ? "e" + i : "o" + i)
                .collect(Collectors.joining(","));


    }


    public static void main(String[] args) {
//        test();
        new HotelRating().getMostRatedHotel(
                Arrays.asList("poz", "NSA", "agent"),
                Arrays.asList("neg", "joke"),
                Arrays.asList("hotel1", "hotel2"),
                Arrays.asList("NSA agent walks into a bar. Bartender says, poz " +
                        "'Hey, I have a new joke for you.' Agent says, 'heard it'.", "poz poz neg"));
    }

    private static void test() {
        String test = "I am, preparing for java interview yes ::java yes, /java";
        String[] tokens = test.split("\\s");
        String[] tokens2 = Arrays.stream(tokens)
                .map(w -> w.replaceAll("[^a-zA-Z]", "").toLowerCase().trim())
                .filter(w -> w.length() >0)
                .toArray(String[]::new);

        System.out.println(tokens2.length);

        for (String str: tokens2){
            System.out.println("<" + str + ">");
        }

        Map<String, Long> wordCountMap = Arrays.stream(tokens)
                .map(w -> w.replaceAll("[^a-zA-Z]", "").toLowerCase().trim())
                .filter(w -> w.length() >0)
                .collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));
//        wordCountMap.forEach((k, v) -> System.out.println(k + ":" + v));

        Map<String, Long> sortedWordCountMap = wordCountMap.entrySet().stream()
                .sorted( Map.Entry.comparingByValue() )
                .collect(
                        Collectors.toMap(
                                Map.Entry::getKey,
                                Map.Entry::getValue,
                                (e1, e2) -> e1,
                                LinkedHashMap::new)
                );

        sortedWordCountMap.forEach((k, v) -> System.out.println(k + ":" + v));

        String str = "1.2";
        float fl = Float.parseFloat(str);
        System.out.println(fl);
        int x = 3;
        int y = ++x*4/x-- + --x;
        System.out.println(x+y);

        Integer[] arr = {1,2,3,4};

        arr[1] = null;
        for (Integer a: arr) {
            System.out.println(a);
        }

        Object num = new Integer(2);
        String str1 = (String) num;
        System.out.println(str1);
    }
}
