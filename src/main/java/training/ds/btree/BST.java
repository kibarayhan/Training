package training.ds.btree;

public class BST {
    Node root;
    // to use at isBTS(node) function
	private static Integer lastVisited = null;

    BST() {
        root = null;
    }

    public static void main(String[] args) {

		Node root2 = new Node(50);
		Node left2 = new Node(15);
		Node right2 = new Node(62);
		root2.left = left2;
		root2.right = right2;

		Node left21 = new Node(5);
		Node right21 = new Node(55);
		left2.left = left21;
		left2.right = right21;
//		System.out.println("isBTS(bst.root) = " + isBST(root2, Integer.MIN_VALUE, Integer.MAX_VALUE));
		System.out.println("isBTS(bst.root) = " + isBST(root2));


		BST bst = new BST();
		bst.insertRec(20);
		bst.insertRec(15);
		bst.insertRec(28);
		bst.insertRec(5);
		bst.insertRec(16);
		System.out.println("is Binary Search Tree : " + isBST(bst.root, Integer.MIN_VALUE, Integer.MAX_VALUE));
        inOrderTraversal(bst.root);

        System.out.println("\n>> 6 is found : " + (search(bst.root, 6) != null));
        System.out.println("\n>> 16 is found : " + (search(bst.root, 16) != null));

		System.out.println("\n>> insert 22");
        insertRec(bst.root, 22);
        inOrderTraversal(bst.root);

		System.out.println("\n>> insert 10");
		insertRec(bst.root, 10);
		inOrderTraversal(bst.root);


//		delete(bst.root, 5);
//		delete(bst.root, 16);
		System.out.println("\n>> delete 20");
		delete(bst.root, 20);
		inOrderTraversal(bst.root);
		System.out.println();
    }

	public static boolean isBST(Node node){
		if  (node == null) return true;

    	if (!isBST(node.left)) return false;

    	if (lastVisited != null && lastVisited >= node.value) return false;
		lastVisited = node.value;

		if (!isBST(node.right)) return false;
		return true;
	}

    public static boolean isBST(Node node, int min, int max){
    	if (node == null) return true;
    	if (node.value < min || node.value > max) return false;
    	if (!isBST(node.left, min, node.value) || !isBST(node.right, node.value, max)) return false;
		return true;
	}

	public static Node search(Node node, int val) {
        // Base Cases: root is null or val is present at root
        if (node == null || node.value == val)
            return node;
        // val is less than root's val
        if (val < node.value) {
            return search(node.left, val);
        }

        return search(node.right, val);
    }

    // This method mainly calls insertRec()
    void insertRec(int key) {
        root = insertRec(root, key);
    }

    /* A recursive function to insert a new key in BST */
    public static Node insertRec(Node root, int val) {
        /* If the tree is empty, return a new node */
        if (root == null) {
            root = new Node(val);
            return root;
        }

        /* Otherwise, recur down the tree */
        if (val < root.value) {
			root.left = insertRec(root.left, val);
        }else{
			root.right = insertRec(root.right, val);
		}
		return root;
    }

    public static Node delete(Node root, int val){
    	if (root == null){
    		return null;
		}

    	if (val < root.value){
			root.left = delete(root.left, val);
		}else if (val > root.value){
			root.right = delete(root.right, val);
		}else{
			if (root.left == null) {
				return root.right;
			}else if (root.right == null){
				return root.left;
			}
			// node with two children: Get the inorder successor (smallest in the right subtree)
			root.value = minValue(root.right);
			// Delete the inorder successor
			root.right = delete(root.right, root.value);
		}
    	return root;
	}

	private static int minValue(Node root) {
    	Node n = root;
    	int min = n.value;
    	while(n.left != null){
    		min = n.left.value;
    		n = n.left;
		}
    	return min;

	}

	// A utility function to do inorder traversal of BST
    static void inOrderTraversal(Node root) {
        if (root != null) {
            inOrderTraversal(root.left);
            System.out.print(root.value + ",");
            inOrderTraversal(root.right);
        }
    }

	// A utility function to do preorder traversal of BST
	static void preOrderTraversal(Node root) {
		if (root != null) {
			System.out.print(root.value + ",");
			preOrderTraversal(root.left);
			preOrderTraversal(root.right);
		}
	}

	// A utility function to do preorder traversal of BST
	static void postOrderTraversal(Node root) {
		if (root != null) {
			postOrderTraversal(root.left);
			postOrderTraversal(root.right);
			System.out.print(root.value + ",");
		}
	}

	static boolean isBalanced(Node root){
		int left = 0, right = 0;
		if (root.left!=null) left = getHeight(root.left);
		if (root.right!=null) right = getHeight(root.right);
		return Math.abs(left-right) <= 1 ;
	}

	private static int getHeight(Node node) {
    	if (node == null)
    		return -1;

    	int leftHeigth = 0, rightHeight = 0;
    	if (node.left != null)
			leftHeigth = getHeight(node.left);

    	if (node.right != null)
			rightHeight = getHeight(node.right);

    	return Integer.max(leftHeigth, rightHeight) + 1;
	}

}
