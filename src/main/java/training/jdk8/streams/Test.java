package training.jdk8.streams;

import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;


public class Test {
	
	List<String> list = Arrays.asList("ayhan", "kibar", "ali", "veli");
	
	public List<String> alphaSortJava7() {
		Collections.sort(list);
		return list;
	}

	// Java 7- using Comparator with anonymous inner class
	public List<String> lengthSortJava7() {
		Collections.sort(list, new Comparator<String>() {
			@Override
			public int compare(String o1, String o2) {
				return o1.length() - o2.length();
			}
		});
		return list;
	}	
	
	
	public List<String> alphaSortJava8() {
		return list.stream().sorted().collect(Collectors.toList());				
	}

	public List<String> lengthSortJava8UsingAnonymouseInnerClass(){
		return list.stream().sorted(new Comparator<String>() {
			@Override
			public int compare(String o1, String o2) {
				return o1.length() - o2.length();
			}
			
		}).collect(Collectors.toList());
	}
	
	public List<String> lengthSortUsingSorted(){
		return list.stream().sorted( (s1, s2) -> s1.length() - s2.length()).collect(Collectors.toList());
	}
	
	public List<String> lengthSortUsingLambda(){
		Collections.sort(list, (s1, s2) -> s1.length() - s2.length());
		return list;
	}
}
