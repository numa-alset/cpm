import 'package:sqflite/sqflite.dart';

import '../database/user_db.dart';
import '../models/user.dart';
import 'base_dao.dart';

class UserDAO extends BaseDAO<User> {
  final UserDB userDB = UserDB();

  @override
  Future<int> insert(User item, Transaction txn) {
    return userDB.insert(item, txn);
  }

  @override
  Future<int> update(User item, Transaction txn) {
    return userDB.update(item, txn);
  }

  @override
  Future<int> softDelete(String unified, Transaction txn) {
    return userDB.delete(unified, txn);
  }

  @override
  Future<User?> getByUnified(String unified, Transaction txn) {
    return userDB.get(unified, txn);
  }

  @override
  Future<List<User>> getAll(Transaction txn) {
    return userDB.getAll(txn);
  }

  Future<List<User>> search(String keyword, Transaction txn) {
    final allUsers = userDB.getAll(txn);
    final filtered = allUsers.then(
      (users) => users
          .where(
            (user) => user.name.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList(),
    );
    return filtered;
  }

  Future<bool> isExist(String keyword, Transaction txn) {
    final allUsers = userDB.getAll(txn);
    final filtered = allUsers.then(
      (users) => users.any((user) => user.name == keyword),
    );
    return filtered;
  }

  @override
  Future<List<User>> getNotScheduled(Transaction txn) {
    return userDB.getUnsynced(txn);
  }

  @override
  Future<int> markSync(String unified, Transaction txn) {
    return userDB.markSync(unified, txn);
  }
}
