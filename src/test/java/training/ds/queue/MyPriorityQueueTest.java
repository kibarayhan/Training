package training.ds.queue;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class MyPriorityQueueTest {

    @Test
    public void TestAddAndRemoveItems(){
        MyPriorityQueue q = new MyPriorityQueue(10);
        q.add(15);
		assertEquals(q.items[0], 15);
        q.printItems();

        q.add(20);
		assertEquals(q.items[0], 20);
		assertEquals(q.items[1], 15);
        q.printItems();

        q.add(6);
		assertEquals(q.items[0], 20);
		assertEquals(q.items[1], 15);
		assertEquals(q.items[2], 6);
        q.printItems();

        q.add(28);
        q.printItems();
		assertEquals(q.items[0], 28);
		assertEquals(q.items[1], 20);
		assertEquals(q.items[2], 6);
		assertEquals(q.items[3], 15);

        q.remove();
        q.printItems();
    }

}
