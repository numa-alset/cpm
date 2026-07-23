import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../dao/user_dao.dart';
import '../models/user.dart';

class UserRepository extends BaseRepository<User> {
  final UserDAO _userDAO;

  UserRepository(this._userDAO);

  @override
  Future<int> create(User user, Transaction txn) => _userDAO.insert(user, txn);

  @override
  Future<int> update(User user, Transaction txn) => _userDAO.update(user, txn);

  @override
  Future<int> delete(String unified, Transaction txn) =>
      _userDAO.softDelete(unified, txn);

  @override
  Future<User?> get(String unified, Transaction txn) =>
      _userDAO.getByUnified(unified, txn);
  Future<List<User>> getAll(Transaction txn) => _userDAO.getAll(txn);

  Future<List<User>> getBuyers(Transaction txn) => _userDAO.getBuyers(txn);

  Future<List<User>> getSellers(Transaction txn) => _userDAO.getSellers(txn);

  Future<List<User>> search(String keyword, Transaction txn) =>
      _userDAO.search(keyword, txn);
  Future<bool> isExist(String keyword, Transaction txn) =>
      _userDAO.isExist(keyword, txn);

  Future<int> changeBalance(String unified, double total, Transaction txn) =>
      _userDAO.updateBalance(unified, total, txn);

  @override
  Future<List<User>> getNotScheduled(Transaction txn) {
    return _userDAO.getNotScheduled(txn);
  }
}
