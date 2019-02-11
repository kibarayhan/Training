package training.pattern.factory;

public class Library implements BookFactory{

	@Override
	public Book getBook() {
		return new LibraryBook();
	}

}
