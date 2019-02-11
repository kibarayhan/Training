package training.visibility;

public class SubClass extends Parent implements Parent.ProtectedInterface {

	@Override
	protected void protectedAction() {
		// Calls parent’s method implementation
		super.protectedAction();
	}

	@Override
	void packageAction() {
		// Do nothing, no call to parent’s method implementation
	}

	public void childAction() {
		this.protectedField = "value";
	}

	@Override
	public void aMthod() {
		// method from protectedInteface
	}

}
