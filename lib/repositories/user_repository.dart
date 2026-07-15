import 'package:naji/repositories/base_repository.dart';

import '../dao/user_dao.dart';
import '../models/user.dart';

class UserRepository extends BaseRepository<User> {
  final UserDAO _userDAO;

  UserRepository(this._userDAO);

  @override
  Future<int> create(User user) => _userDAO.insert(user);

  @override
  Future<int> update(User user) => _userDAO.update(user);

  @override
  Future<int> delete(String unified) => _userDAO.softDelete(unified);

  @override
  Future<User?> get(String unified) => _userDAO.getByUnified(unified);

  @override
  Future<List<User>> getAll() => _userDAO.getAll();

  Future<List<User>> getBuyers() => _userDAO.getBuyers();

  Future<List<User>> getSellers() => _userDAO.getSellers();

  Future<List<User>> search(String keyword) => _userDAO.search(keyword);
  Future<bool> isExist(String keyword) => _userDAO.isExist(keyword);

  Future<int> changeBalance(String unified, double total) =>
      _userDAO.updateBalance(unified, total);

  @override
  Future<List<User>> getNotScheduled() {
    return _userDAO.getNotScheduled();
  }
}
