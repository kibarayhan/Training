package training.ds.linkedlist;

public class MergeSortedLinkedLists {

    public static void main(String[] args) {
        ListNode[] lists = new ListNode[3];
        lists[0] = new ListNode(1);
        lists[0].next = new ListNode(4);
        lists[0].next.next = new ListNode(5);

        lists[1] = new ListNode(1);
        lists[1].next = new ListNode(3);
        lists[1].next.next = new ListNode(4);

        lists[2] = new ListNode(2);
        lists[2].next = new ListNode(6);

        MergeSortedLinkedLists s = new MergeSortedLinkedLists();
        ListNode result = s.mergeKLists(lists);
        while(result != null){
            System.out.print(result.val + ", ");
            result = result.next;
        }
    }

    public ListNode mergeKLists(ListNode[] lists) {
        ListNode head = null;

        for(ListNode node: lists){
            if (head == null){
                head = node;
            }else{
                ListNode temp = head;
                ListNode prev = head;
                while(temp != null && node!=null){
                    while(temp.next!=null && temp.val==temp.next.val){
                        temp = temp.next;
                        prev = prev.next;
                    }

                    if (temp.val<=node.val){
                        while (temp.next != null && temp.next.val<node.val){
                            prev = temp;
                            temp = temp.next;
                        }

                            ListNode next = temp.next;
                            temp.next = node;
                            node = node.next;
                            temp.next.next = next;
                            prev = temp.next;
                            temp = next;

                    }else{
                        prev.next = node;
                        node = node.next;
                        prev.next.next = temp;
                        prev = temp;
                        temp = temp.next;
                    }
                }

                if (temp == null){
                    prev.next = node;
                }

            }
        }

        return head;
    }


    private static class ListNode {
        int val;
        ListNode next;

        ListNode(int x) {
            val = x;
        }
    }
}
