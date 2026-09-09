import 'package:naji/core/models/currency.dart';
import 'package:sqflite/sqflite.dart';

import '../dao/user_dao.dart';
import '../models/user.dart';
import '../models/user_balance.dart';
import 'base_repository.dart';

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

  @override
  Future<List<User>> getAll(Transaction txn) => _userDAO.getAll(txn);

  Future<List<User>> search(String keyword, Transaction txn) =>
      _userDAO.search(keyword, txn);
  Future<bool> isExist(String keyword, Transaction txn) =>
      _userDAO.isExist(keyword, txn);

  Future<UserBalance> getUserBalance(
    String userUnified,
    Transaction txn,
  ) async {
    final result = await txn.rawQuery(
      '''
    SELECT
      COALESCE((
        SELECT SUM(totalSy)
        FROM fatoras
        WHERE userUnified = ?
          AND deletedAt IS NULL
      ), 0)
      -
      COALESCE((
        SELECT SUM(amount)
        FROM payments
        WHERE userUnified = ?
          AND currency = '${Currency.sy.value}'
          AND deletedAt IS NULL
      ), 0) AS balanceSy,

      COALESCE((
        SELECT SUM(totalDollar)
        FROM fatoras
        WHERE userUnified = ?
          AND deletedAt IS NULL
      ), 0)
      -
      COALESCE((
        SELECT SUM(amount)
        FROM payments
        WHERE userUnified = ?
          AND currency = '${Currency.dollar.value}'
          AND deletedAt IS NULL
      ), 0) AS balanceDollar
    ''',
      [userUnified, userUnified, userUnified, userUnified],
    );

    // A SELECT with subqueries always returns 1 row, but checking is safe
    if (result.isEmpty) {
      return const UserBalance(sy: 0.0, dollar: 0.0);
    }

    final row = result.first;

    return UserBalance(
      sy: (row['balanceSy'] as num?)?.toDouble() ?? 0.0,
      dollar: (row['balanceDollar'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<List<User>> getNotScheduled(Transaction txn) {
    return _userDAO.getNotScheduled(txn);
  }

  @override
  Future<int> markSync(String unified, Transaction txn) {
    return _userDAO.markSync(unified, txn);
  }
}
