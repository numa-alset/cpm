import 'package:flutter/material.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/locator/locator.dart';

import '../controllers/users_controller.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UsersController controller = getIt<UsersController>();
  @override
  void initState() {
    super.initState();

    controller.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.load();
    });
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _reload() async {
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to Add User Screen
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Add User"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.search,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.searchController.clear();
                          controller.load();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (controller.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.users.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      children: const [
                        SizedBox(height: 150),
                        Icon(
                          Icons.people_outline,
                          size: 90,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: controller.users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final User user = controller.users[index];

                      return ListTile(
                        onTap: () {
                          // TODO:
                          // context.push("/users/${user.unified}");
                        },
                        leading: CircleAvatar(
                          child: Text(
                            user.name.isEmpty
                                ? "?"
                                : user.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.location),
                            const SizedBox(height: 4),
                            Text(
                              user.type == UserType.buyer ? "Buyer" : "Seller",
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Balance",
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              user.total.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: user.total >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
