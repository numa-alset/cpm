import 'package:flutter/material.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/user_service.dart';

class UsersController extends ChangeNotifier {
  final UserService _service;

  UsersController(this._service);

  final TextEditingController searchController = TextEditingController();

  List<User> _users = [];
  bool _loading = false;

  List<User> get users => _users;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _users = await _service.getAllUsers();

    _loading = false;
    notifyListeners();
  }

  Future<void> search(String text) async {
    if (text.trim().isEmpty) {
      await load();
      return;
    }

    _loading = true;
    notifyListeners();

    _users = await _service.searchUsers(text);

    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
