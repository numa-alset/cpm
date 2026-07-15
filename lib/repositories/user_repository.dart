import '../dao/user_dao.dart';
import '../models/user.dart';

class UserRepository {
  final UserDAO _userDAO;

  UserRepository(this._userDAO);

  Future<int> create(User user) => _userDAO.insert(user);

  Future<int> update(User user) => _userDAO.update(user);

  Future<int> delete(String unified) => _userDAO.softDelete(unified);

  Future<User?> get(String unified) => _userDAO.getByUnified(unified);

  Future<List<User>> getAll() => _userDAO.getAll();

  Future<List<User>> getBuyers() => _userDAO.getBuyers();

  Future<List<User>> getSellers() => _userDAO.getSellers();

  Future<List<User>> search(String keyword) => _userDAO.search(keyword);
  Future<bool> isExist(String keyword) => _userDAO.isExist(keyword);

  Future<int> changeBalance(String unified, double total) =>
      _userDAO.updateBalance(unified, total);
}
