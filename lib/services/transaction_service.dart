import '../database/database_helper.dart';

class TransactionService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<T> runTransaction<T>(Future<T> Function() action) async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      try {
        return await action();
      } catch (e) {
        throw Exception("Transaction failed: $e");
      }
    });
  }
}
