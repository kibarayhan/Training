package training.ds.stack;

public class MyStack<T> {
	private static int MAX_SIZE = 10;
	private int index = 0;
	String[] data;

	public MyStack(int size) {
		MAX_SIZE = size;
		data = new String[MAX_SIZE];
	}

	public MyStack() {
		data = new String[MAX_SIZE];
	}

	public void push(String data) throws Exception {
		if (index > MAX_SIZE) {
			throw new Exception("Stack is FULL!!!");
		}
		this.data[index] = data;
		index++;
	}

	public String pop() throws Exception {
		if (index <= 0) {
			throw new Exception("Stack is EMPTY!!!");
		}
		index--;
		return this.data[index];
	}
}
