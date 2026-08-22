import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/user_service.dart';

enum UsersFilter { all }

class UsersController extends ChangeNotifier {
  final UserService _userService;

  UsersController(this._userService);

  final TextEditingController searchController = TextEditingController();

  List<User> users = [];
  bool loading = false;
  String? error;
  UsersFilter filter = UsersFilter.all;

  /// Main method to fetch users respecting both active filters and search query
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final query = searchController.text.trim();

      if (query.isNotEmpty) {
        final result = await _userService.searchUsers(query);
        _applyFilterToResult(result);
      } else {
        switch (filter) {
          case UsersFilter.all:
            users = await _userService.getAllUsers();
            break;
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyFilterToResult(List<User> result) {
    switch (filter) {
      case UsersFilter.all:
        users = result;
        break;
    }
  }

  Future<void> setFilter(UsersFilter value) async {
    if (filter == value) return;
    filter = value;
    await load();
  }

  Future<void> search(String keyword) async {
    await load();
  }

  Future<bool> addUser(User user) async {
    error = null;
    try {
      await _userService.createUser(user);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    error = null;
    try {
      await _userService.updateUser(user);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String unified) async {
    error = null;
    try {
      loading = true;
      notifyListeners();

      await _userService.deleteUser(unified);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeBalance(
    String unified,
    double newBalance,
    Currency currency,
  ) async {
    error = null;
    try {
      loading = true;
      notifyListeners();

      await _userService.changeBalance(unified, newBalance, currency);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<User?> getUser(String unified) async {
    try {
      return await _userService.getUser(unified);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
