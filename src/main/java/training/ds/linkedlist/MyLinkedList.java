package training.ds.linkedlist;

public class MyLinkedList<T> {
    private Node<T> head;
    private int size;

    public static void main(String[] args){
        MyLinkedList<Integer> myLinkedList = new MyLinkedList<>();
        myLinkedList.addToTail(1);
        myLinkedList.addToTail(2);
        myLinkedList.addToTail(3);
        myLinkedList.addToTail(4);
        myLinkedList.addToTail(5);
        myLinkedList.addToTail(6);
        myLinkedList.addToTail(10);
        myLinkedList.printItems();
        Integer current = myLinkedList.findKthToLast(5);
        System.out.println("5th element to last is:" + current);
    }

    public T findKthToLast(int idx){
        Node<T> current = head;
        Node<T> runner = head;

        for(int i = 0; i < idx;i++){
            if (runner == null) return null; // out of range
            runner = runner.next;
        }

        while(runner.next != null){
            runner = runner.next;
            current = current.next;
        }

        return current.item;
    }

    public void printItems() {
        Node<T> n = head;
        System.out.println("Elements are:");
        while(n != null){
            System.out.print(n.item + ",");
            n = n.next;
        }
        System.out.println();
    }

    class Node<T>{
        T item;
        Node<T> next;

        Node(T item){
            super();
            this.item = item;
        }
    }

    public void addToTail(T item){
        Node<T> end = new Node<>(item);
        if (head == null){
            head = end;
        }else{
            Node<T> n = head;
            while(n.next != null){
                n = n.next;
            }
            n.next = end;
        }
        size++;
    }

    public Node<T> delete(T item){
        if (head.item.equals(item)){
            size--;
            head = head.next;
        }else{
            Node<T> n = head;
            while (n.next != null){
                if (n.next.item.equals(item)){
                    n.next = n.next.next;
                    size--;
                    break;
                }
                n = n.next;
            }
        }
        return head;
    }

    public int getSize(){
        return size;
    }
}
