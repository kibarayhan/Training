package training.ds.btree;

public class BTree {

	public static void main(String[] args) {
		Node root = new Node(20);
		Node root15 = new Node(15);
		Node root28 = new Node(28);
		Node root5 = new Node(5);
		Node root16 = new Node(16);

		root.left = root15;
		root.right = root28;

		root15.left = root5;
		root15.right = root16;

		System.out.println(search(root, 6));
		
		insert(root, 22);
		inorderRec(root);
	}

	public static Node search(Node node, int key) {
		if (node == null || node.value == key)
			return node;

		if (node.value > key) {
			return search(node.left, key);
		}

		return search(node.right, key);
	}
	
	public static Node insert(Node root, int key) {
		if (root == null) {
			root = new Node(key);
			return root;
		}
		
		if (root.value > key) {
			return insert (root.left, key);
		}

		return insert (root.right, key);
	}
	
	// A utility function to do inorder traversal of BST 
    static void inorderRec(Node root) { 
        if (root != null) { 
            inorderRec(root.left); 
            System.out.println(root.value); 
            inorderRec(root.right); 
        } 
    }
    
}
