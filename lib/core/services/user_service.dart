import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/user_balance.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/core/services/id_service.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'transaction_service.dart';

class UserService {
  final UserRepository _userRepository;
  final TransactionService _transactionService;

  UserService(this._userRepository, this._transactionService);

  Future<void> createUser(User user) async {
    await _transactionService.runTransaction((txn) async {
      // Validate user details
      if (user.name.isEmpty) {
        throw Exception("User name cannot be empty");
      }
      if (await _userRepository.isExist(user.name, txn)) {
        throw Exception("User name already exists");
      }

      // Generate UUID, timestamps, and add to sync queue
      user = user.copyWith(
        unified: generateUUID(),
        deviceId: DeviceService.deviceIdKey,
        status: Status.notScheduled,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _userRepository.create(user, txn);
    });
  }

  Future<void> updateUser(User user) async {
    await _transactionService.runTransaction((txn) async {
      // Validate user details
      if (user.name.isEmpty) {
        throw Exception("User name cannot be empty");
      }
      final old = await _userRepository.get(user.unified, txn);
      if (old?.name != user.name) {
        if (await _userRepository.isExist(user.name, txn)) {
          throw Exception("User name already exists");
        }
      }
      user = user.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        status: Status.notScheduled,
      );
      await _userRepository.update(user, txn);
    });
  }

  Future<void> deleteUser(String unified) async {
    await _transactionService.runTransaction((txn) async {
      // Update status to not scheduled before deletion
      final user = await _userRepository.get(unified, txn);
      if (user == null) {
        throw Exception("User not found");
      }

      await _userRepository.update(
        user.copyWith(status: Status.notScheduled),
        txn,
      );

      await _userRepository.delete(unified, txn);
    });
  }

  Future<User?> getUser(String unified) async {
    return await _transactionService.runTransaction((txn) async {
      return await _userRepository.get(unified, txn);
    });
  }

  Future<UserBalance> getUserBalance(String unified) async {
    return await _transactionService.runTransaction((txn) async {
      return await _userRepository.getUserBalance(unified, txn);
    });
  }

  Future<List<User>> getAllUsers() async {
    return await _transactionService.runTransaction((txn) async {
      return await _userRepository.getAll(txn);
    });
  }

  Future<List<User>> searchUsers(String keyword) async {
    return await _transactionService.runTransaction((txn) async {
      return await _userRepository.search(keyword, txn);
    });
  }

  Future<List<User>> getNotScheduledUsers() async {
    return await _transactionService.runTransaction((txn) async {
      return await _userRepository.getNotScheduled(txn);
    });
  }

  Future<int> markScheduled(User user, Transaction txn) async {
    return await _userRepository.markSync(user.unified, txn);
  }

  String generateUUID() {
    return IdService.generate();
  }
}
