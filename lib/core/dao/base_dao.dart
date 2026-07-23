import 'package:sqflite/sqflite.dart';

abstract class BaseDAO<T> {
  Future<int> insert(T item, Transaction txn);

  Future<int> update(T item, Transaction txn);

  Future<int> softDelete(String unified, Transaction txn);

  Future<T?> getByUnified(String unified, Transaction txn);

  Future<List<T>> getAll(Transaction txn);

  Future<List<T>> getNotScheduled(Transaction txn);
}
