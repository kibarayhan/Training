package training.ds.stack;

import java.util.LinkedList;
import java.util.Queue;

public class MyStackWithQueue {
    Queue<Integer> q1;
    Queue<Integer> q2;
    /** Initialize your data structure here. */
    public MyStackWithQueue() {
        q1 = new LinkedList<>();
        q2 = new LinkedList<>();
    }

    /** Push element x onto stack. */
    public void push(int x) {
        q1.add(x);
    }

    /** Removes the element on top of the stack and returns that element. */
    public int pop() {
        int item = -1;
        while(!q1.isEmpty()){
            item = q1.remove();
            if (!q1.isEmpty()){
                q2.add(item);
            }
        }

        while(!q2.isEmpty()){
            q1.add(q2.remove());
        }

        return item;
    }

    /** Get the top element. */
    public int top() {
        int item = -1;
        while(!q1.isEmpty()){
            item = q1.remove();
        }

        while(!q2.isEmpty()){
            q1.add(q2.remove());
        }

        return item;
    }

    /** Returns whether the stack is empty. */
    public boolean empty() {
        return q1.isEmpty();
    }
}
