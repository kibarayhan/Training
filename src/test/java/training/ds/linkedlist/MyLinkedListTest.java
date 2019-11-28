package training.ds.linkedlist;

import org.junit.Assert;
import org.junit.Test;

public class MyLinkedListTest {

    @Test
    public void addToLinkedList(){
        MyLinkedList<Integer> myLinkedList = new MyLinkedList<>();
        myLinkedList.addToTail(1);
        myLinkedList.printItems();
        myLinkedList.addToTail(2);
        myLinkedList.printItems();
        Assert.assertEquals(2, myLinkedList.getSize());
    }
}
