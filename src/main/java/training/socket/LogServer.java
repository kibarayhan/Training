package training.socket;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.time.LocalDateTime;
import java.util.Scanner;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class LogServer {

	public static void main(String[] args) {
		try {
			new LogServer();
		} catch (IOException e) {
			e.printStackTrace();
		}
		System.out.println("Server is shut down.");
	}

	public LogServer() throws IOException {
		try (ServerSocket serverSocket = new ServerSocket(9999)) {
			System.out.println("Server started, " + serverSocket);
			ExecutorService pool = Executors.newFixedThreadPool(5);
			File file = new File("log.txt");
			
			while (true) {
				pool.execute(new Handler(serverSocket.accept(), file));
			}
		}
	}

	public class Handler implements Runnable {
		private final Socket socket;
		private final FileWriter fw;
		
		
		Handler(Socket socket, File file) throws IOException{
			this.socket = socket;
			this.fw = new FileWriter(file, true);
			System.out.println("client connected, " + socket);
		}

		public void run() {
			try (Scanner in = new Scanner(socket.getInputStream())){
				while (in.hasNextLine()) {
					String msg = in.nextLine();
					fw.write(socket.getPort() + "," + LocalDateTime.now() + ":" + msg + "\n");
					fw.flush();
//					System.out.println("message received : " + socket + ":" + msg);
				}
			} catch (IOException e) {
				e.printStackTrace();
			}finally {
				try {socket.close();fw.close();} catch (IOException e) {}
				System.out.println("Client closed: " + socket);
			}
		}
	}
}
