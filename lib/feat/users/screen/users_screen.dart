import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/feat/users/widget/delete_user_dialog.dart';
import 'package:naji/feat/users/widget/user_card.dart';
import 'package:naji/feat/users/widget/user_form_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user.dart';
import '../controllers/users_controller.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GetIt.I<UsersController>()..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UsersController>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text("إضافة"),
        onPressed: () async {
          final refresh = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => UserFormBottomSheet(controller: controller),
          );

          if (refresh == true) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("تمت إضافة المستخدم")));
          }
        },
      ),

      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Column(
          children: [
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: "بحث...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.searchController.clear();
                            controller.load();
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: controller.search,
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("الكل"),
                      selected: controller.filter == UsersFilter.all,
                      onSelected: (_) => controller.setFilter(UsersFilter.all),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ChoiceChip(
                      label: const Text("المشترون"),
                      selected: controller.filter == UsersFilter.buyers,
                      onSelected: (_) =>
                          controller.setFilter(UsersFilter.buyers),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ChoiceChip(
                      label: const Text("البائعون"),
                      selected: controller.filter == UsersFilter.sellers,
                      onSelected: (_) =>
                          controller.setFilter(UsersFilter.sellers),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Builder(
                builder: (_) {
                  if (controller.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              controller.error!,
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 20),

                            FilledButton(
                              onPressed: controller.load,
                              child: const Text("إعادة المحاولة"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (controller.users.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 70,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 16),

                          Text(
                            "لا يوجد مستخدمون",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 100,
                    ),
                    itemCount: controller.users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final User user = controller.users[index];

                      return UserCard(
                        user: user,

                        onTap: () {
                          context.push(
                            AppRouter.userDetailsPath,
                            extra: user.unified,
                          );
                        },

                        onEdit: () async {
                          final refresh = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => UserFormBottomSheet(
                              user: user,
                              controller: controller,
                            ),
                          );

                          if (refresh == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تم تحديث المستخدم"),
                              ),
                            );
                          }
                        },

                        onDelete: () async {
                          final delete = await showDeleteUserDialog(
                            context,
                            user,
                          );

                          if (delete == true) {
                            await controller.deleteUser(user.unified);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
