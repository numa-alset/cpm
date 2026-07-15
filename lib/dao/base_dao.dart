abstract class BaseDAO<T> {
  Future<int> insert(T item);

  Future<int> update(T item);

  Future<int> softDelete(String unified);

  Future<T?> getByUnified(String unified);

  Future<List<T>> getAll();
}
