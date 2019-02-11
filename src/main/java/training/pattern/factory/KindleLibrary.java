package training.pattern.factory;

public class KindleLibrary implements BookFactory{

	@Override
	public Book getBook() {
		return new KindleBook();
	}

}
