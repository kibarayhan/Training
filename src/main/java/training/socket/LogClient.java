package training.socket;

import java.io.PrintWriter;
import java.net.Socket;
import java.util.Scanner;

public class LogClient {

	public static void main(String[] args) throws Exception {
		
		try (Socket socket = new Socket("127.0.0.1", 9999)) {
			PrintWriter outp = new PrintWriter(socket.getOutputStream(), true);

			try(Scanner in = new Scanner(System.in)){
				while (in.hasNextLine()) {
					String msg = in.nextLine();
					outp.println(msg);
				}
			}
		}
	}
}
