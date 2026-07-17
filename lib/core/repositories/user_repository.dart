import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../dao/user_dao.dart';
import '../models/user.dart';

class UserRepository extends BaseRepository<User> {
  final UserDAO _userDAO;

  UserRepository(this._userDAO);

  @override
  Future<int> create(User user, {Transaction? txn}) =>
      _userDAO.insert(user, txn: txn);

  @override
  Future<int> update(User user, {Transaction? txn}) =>
      _userDAO.update(user, txn: txn);

  @override
  Future<int> delete(String unified, {Transaction? txn}) =>
      _userDAO.softDelete(unified, txn: txn);

  @override
  Future<User?> get(String unified, {Transaction? txn}) =>
      _userDAO.getByUnified(unified, txn: txn);

  @override
  Future<List<User>> getAll() => _userDAO.getAll();

  Future<List<User>> getBuyers() => _userDAO.getBuyers();

  Future<List<User>> getSellers() => _userDAO.getSellers();

  Future<List<User>> search(String keyword) => _userDAO.search(keyword);
  Future<bool> isExist(String keyword) => _userDAO.isExist(keyword);

  Future<int> changeBalance(String unified, double total, Transaction? txn) =>
      _userDAO.updateBalance(unified, total, txn);

  @override
  Future<List<User>> getNotScheduled() {
    return _userDAO.getNotScheduled();
  }
}
