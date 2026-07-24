import 'package:flutter/material.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/user_service.dart';

enum UsersFilter { all, buyers, sellers }

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
          case UsersFilter.buyers:
            users = await _userService.getBuyers();
            break;
          case UsersFilter.sellers:
            users = await _userService.getSellers();
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
      case UsersFilter.buyers:
        users = result.where((e) => e.type == UserType.buyer).toList();
        break;
      case UsersFilter.sellers:
        users = result.where((e) => e.type == UserType.seller).toList();
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

  Future<bool> changeBalance(String unified, double newBalance) async {
    error = null;
    try {
      loading = true;
      notifyListeners();

      await _userService.changeBalance(unified, newBalance);
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
