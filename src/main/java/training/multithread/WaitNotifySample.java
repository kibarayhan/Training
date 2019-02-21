package training.multithread;

public class WaitNotifySample {

	public static void main(String[] args) {
		SharedResource src = new SharedResource("init");
		new Thread(() -> System.out.println(src.getMsg())).start();
		new Thread(() -> src.setMsg("message")).start();
	}

	private static class SharedResource {

		String msg;

		public SharedResource(String msg) {
			this.msg = msg;
		}

		public synchronized String getMsg() {
			while (msg == null || msg.equals("init")) {
				try {
					wait();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
			
			return msg;
		}

		public synchronized void setMsg(String msg) {
			this.msg = msg;
			notify();
		}

	}
}
