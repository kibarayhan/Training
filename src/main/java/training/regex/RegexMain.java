package training.regex;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RegexMain {

	public static void main(String[] args) {
		String regex = "(^[1-31])/([1-12])/([1900-2000])$";
		
		regex = "^[0-3]?[0-9]/[0-3]?[0-9]/(?:[0-9]{2})?[0-9]{2}$";
		Pattern p = Pattern.compile(regex);
		Matcher m = p.matcher("39/01/1979");
		if (!m.matches()) {
			System.err.println("No match");
		}else {
			System.out.println("Good");			
		}
	}

}
