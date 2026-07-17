import 'package:naji/core/models/enum_status.dart';
import 'package:sqflite/sqflite.dart';

import '../database/user_db.dart';
import '../models/user.dart';
import 'base_dao.dart';

class UserDAO extends BaseDAO<User> {
  final UserDB userDB = UserDB();

  @override
  Future<int> insert(User item, {Transaction? txn}) {
    return userDB.insert(item, txn);
  }

  @override
  Future<int> update(User item, {Transaction? txn}) {
    return userDB.update(item, txn);
  }

  @override
  Future<int> softDelete(String unified, {Transaction? txn}) {
    return userDB.delete(unified, txn);
  }

  @override
  Future<User?> getByUnified(String unified, {Transaction? txn}) {
    return userDB.get(unified);
  }

  @override
  Future<List<User>> getAll({Transaction? txn}) {
    return userDB.getAll(txn: txn);
  }

  Future<List<User>> getBuyers() {
    final allUsers = userDB.getAll();
    final filtered = allUsers.then(
      (users) => users.where((user) => user.type == UserType.buyer).toList(),
    );
    return filtered;
  }

  Future<List<User>> getSellers() {
    final allUsers = userDB.getAll();
    final filtered = allUsers.then(
      (users) => users.where((user) => user.type == UserType.seller).toList(),
    );
    return filtered;
  }

  Future<List<User>> search(String keyword) {
    final allUsers = userDB.getAll();
    final filtered = allUsers.then(
      (users) => users
          .where(
            (user) => user.name.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList(),
    );
    return filtered;
  }

  Future<bool> isExist(String keyword) {
    final allUsers = userDB.getAll();
    final filtered = allUsers.then(
      (users) => users.any((user) => user.name == keyword),
    );
    return filtered;
  }

  Future<int> updateBalance(String unified, double total, Transaction? txn) {
    return userDB.get(unified).then((user) {
      if (user != null) {
        final updatedUser = user.copyWith(total: user.total + total);
        return userDB.update(updatedUser, txn);
      }
      return 0;
    });
  }

  @override
  Future<List<User>> getNotScheduled({Transaction? txn}) {
    final allFatoras = userDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where((fatora) => fatora.status == Status.notScheduled)
          .toList(),
    );
    return filteres;
  }
}
