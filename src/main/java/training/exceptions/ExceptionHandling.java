package training.exceptions;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;

public class ExceptionHandling {

	public static void main(String[] args) throws FileNotFoundException, IOException {
		try {
			testException(-5);
			testException(-10);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			System.out.println("Releasing resources");
		}

		testException(15);
	}

	public static void testException(int i) throws FileNotFoundException, IOException {
		if (i < 0) {
			FileNotFoundException myException = new FileNotFoundException("Negative Integer " + i);
			throw myException;
		} else if (i > 10) {
			throw new IOException("Only supported for index 0 to 10");
		}

	}

	public static void readFile_Normal_with_UncheckedExeption(final File file) {
		FileInputStream in = null;

		try {
			in = new FileInputStream(file);
			// TODO Implementation
		} catch (Exception e) {
			throw new MyException("Error reading file", e);
		} finally {
			if (in != null) {
				try {
					in.close();
				} catch (IOException e) {
					throw new MyException("Error closing file", e);
				}
			}
		}
	}

	public static void readFile_TryWithResource_with_UncheckedExeption(final File file) {
		try (final FileInputStream in = new FileInputStream(file)) {
			System.out.println("Total file size to read (in bytes) : " + in.available());
			int i;
			// read till the end of the file
	         while((i = in.read())!=-1) {
	            // converts integer to character
	            // prints character
	            System.out.print((char)i);
	         }
	         
		} catch (Exception e) {
			throw new MyException("Error reading file", e);
		}
	}

	public static void readFile_TryWithResource_with_CheckedExeption(File file) throws IOException {
		try (final FileInputStream in = new FileInputStream(file)) {

		} catch (Exception e) {
			throw new IOException("Error reading file", e);
		}
	}

	public void readFile() {
		run(() -> {
			try {
				Files.readAllBytes(new File("some.txt").toPath());
			} catch (IOException e) {
				throw new MyException("Error reading file", e);
			}
		});
	}

	private void run(final Runnable runnable) {
		runnable.run();
	}
}
