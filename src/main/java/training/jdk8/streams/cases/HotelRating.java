package training.jdk8.streams.cases;

import java.util.*;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

public class HotelRating {
    private static final Pattern DELIMITER = Pattern.compile(" ");

    private static <K, V> void printMap(Map<K, V> map) {
        map.forEach((k, v) -> System.out.println(k + ": " + v));
        System.err.println("--------------------------------------");
    }

    public String[] getMostRatedHotel(List<String> positiveWords, List<String> negativeWords, List<String> hotels, List<String> comments) {
    	int idx = 0;
    	
    	Map<String, Long> hotelMapByPoints = new HashMap<>();
    	for(String comment : comments){
//          Map<String, Long> commentRank = Arrays.stream(comment.split(" ")).collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));    		
    		Map<String, Long> commentRank = DELIMITER.splitAsStream(comment).collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));
    		Long pozitivePoints = positiveWords.stream().mapToLong(s -> commentRank.get(s)!=null ? commentRank.get(s)*3 : 0).sum();
    		Long negativePoints = negativeWords.stream().mapToLong(s -> commentRank.get(s)!=null ? commentRank.get(s) : 0).sum();
    		hotelMapByPoints.put(hotels.get(idx++), pozitivePoints - negativePoints);    		
    	}
    	
    	hotelMapByPoints = hotelMapByPoints.entrySet().stream().filter(e -> e.getValue()>5).collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (e1, e2) -> e1, LinkedHashMap::new));
    	
        printMap(hotelMapByPoints);
        return null;
    }

    public static void main(String[] args) {
        new HotelRating().getMostRatedHotel(Arrays.asList("poz"), Arrays.asList("neg"),
                Arrays.asList("hotel1", "hotel2"), Arrays.asList("poz poz poz neg neg", "poz poz neg"));
    }
}
