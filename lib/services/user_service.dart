import 'package:naji/services/id_service.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  Future<void> createUser(User user) async {
    // Validate user details
    if (user.name.isEmpty) {
      throw Exception("User name cannot be empty");
    }
    if (await _userRepository.isExist(user.name)) {
      throw Exception("User name already exists");
    }

    // Generate UUID, timestamps, and add to sync queue
    user = user.copyWith(
      unified: generateUUID(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _userRepository.create(user);
  }

  Future<void> updateUser(User user) async {
    // Validate user details
    if (user.name.isEmpty) {
      throw Exception("User name cannot be empty");
    }
    final old = await _userRepository.get(user.unified);
    if (old?.name != user.name) {
      if (await _userRepository.isExist(user.name)) {
        throw Exception("User name already exists");
      }
    }
    user = user.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _userRepository.update(user);
  }

  Future<void> deleteUser(String unified) async {
    await _userRepository.delete(unified);
  }

  Future<void> changeBalance(String unified, double total) async {
    await _userRepository.changeBalance(unified, total);
  }

  Future<User?> getUser(String unified) async {
    return await _userRepository.get(unified);
  }

  Future<List<User>> getAllUsers() async {
    return await _userRepository.getAll();
  }

  Future<List<User>> getBuyers() async {
    return await _userRepository.getBuyers();
  }

  Future<List<User>> getSellers() async {
    return await _userRepository.getSellers();
  }

  Future<List<User>> searchUsers(String keyword) async {
    return await _userRepository.search(keyword);
  }

  String generateUUID() {
    return IdService.generate();
  }
}
