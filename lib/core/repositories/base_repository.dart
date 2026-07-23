import 'package:sqflite/sqflite.dart';

abstract class BaseRepository<T> {
  Future<int> create(T item, Transaction txn);

  Future<int> update(T item, Transaction txn);

  Future<int> delete(String unified, Transaction txn);

  Future<T?> get(String unified, Transaction txn);

  Future<List<T>> getAll(Transaction txn);

  Future<List<T>> getNotScheduled(Transaction txn);
}
