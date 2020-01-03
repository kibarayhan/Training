package training.ds.linkedlist;

import training.ds.linkedlist.MyLinkedList.Node;

public class LinkedListQuestions {

    public static void main(String[] args) {
        LinkedListQuestions listQuestions = new LinkedListQuestions();
//        TestSumWithOtherList(listQuestions);
        TestIsPolindrome(listQuestions);
        
    }

    private static void TestIsPolindrome(LinkedListQuestions listQuestions) {
        MyLinkedList<String> list1 = new MyLinkedList<>();
        list1.addToTail("a");
        list1.addToTail("b");
        list1.addToTail("c");
        list1.addToTail("b");
        list1.addToTail("a");
        list1.printItems();
        System.out.println("LinkedListQuestions.TestIsPolindrome: " + listQuestions.isPolindrome(list1));
    }

    public boolean isPolindrome(MyLinkedList<String> list){
        Node<String> n = list.getHead();
        Node<String> runner = n;
        Node<String> cur = list.getHead();

        while(runner != null && runner.next != null){
            runner = runner.next.next;
            n = n.next;
        }

        while(n.next != null){
            if (!n.next.item.equals(cur.item)){
                return false;
            }
            n = n.next;
            cur = cur.next;
        }

        return true;
    }

    private static void TestSumWithOtherList(LinkedListQuestions listQuestions) {
        MyLinkedList<Integer> list1 = new MyLinkedList<>();
        list1.addToTail(7);
        list1.addToTail(1);
        list1.addToTail(6);
        MyLinkedList<Integer> list2 = new MyLinkedList<>();
        list2.addToTail(5);
        list2.addToTail(9);
        list2.addToTail(2);

        MyLinkedList<Integer> list3 = listQuestions.sumWithAnotherList(list1, list2);
        list3.printItems();
    }

    public MyLinkedList<Integer> sumWithAnotherList(MyLinkedList<Integer> list1, MyLinkedList<Integer> list2) {
        MyLinkedList<Integer> result = new MyLinkedList<>();
        Node<Integer> n1 = list1.getHead();
        Node<Integer> n2 = list2.getHead();
        Integer sum = 0;
        while (n1 != null || n2 != null) {
            if (n1 != null) sum += n1.item;
            if (n2 != null) sum += n2.item;

            result.addToTail(sum % 10);
            sum /= 10;
            n1 = (n1 != null) ? n1.next : null;
            n2 = (n2 != null) ? n2.next : null;
        }

        return result;
    }

}
