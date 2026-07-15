abstract class BaseRepository<T> {
  Future<int> create(T item);

  Future<int> update(T item);

  Future<int> delete(String unified);

  Future<T?> get(String unified);

  Future<List<T>> getAll();

  Future<List<T>> getNotScheduled();
}
