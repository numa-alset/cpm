import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/feat/users/widget/delete_user_dialog.dart';
import 'package:naji/feat/users/widget/user_card.dart';
import 'package:naji/feat/users/widget/user_form_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user.dart';
import '../../../core/models/user_balance.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(context, controller),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("إضافة مستخدم"),
      ),

      body: Column(
        children: [
          _buildSearchAndFilters(context, controller),

          Expanded(child: _buildContent(context, controller)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH + FILTERS
  // ---------------------------------------------------------------------------

  Widget _buildSearchAndFilters(
    BuildContext context,
    UsersController controller,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: controller.searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: "البحث عن مستخدم...",
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: "مسح",
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.load();
                      },
                    ),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
            onChanged: controller.search,
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context, UsersController controller) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return _buildErrorState(context, controller);
    }

    if (controller.users.isEmpty) {
      return _buildEmptyState(context, controller);
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
        itemCount: controller.users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final User user = controller.users[index];

          return _buildUserItem(context, controller, user);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // USER CARD
  // ---------------------------------------------------------------------------

  Widget _buildUserItem(
    BuildContext context,
    UsersController controller,
    User user,
  ) {
    final balance = controller.balances[user.unified] ?? 
        const UserBalance(sy: 0.0, dollar: 0.0);
    
    return UserCard(
      user: user,
      balance: balance,

      onTap: () {
        context.push(AppRouter.userDetailsPath, extra: user.unified);
      },

      onEdit: () => _editUser(context, controller, user),

      onDelete: () => _deleteUser(context, controller, user),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context, UsersController controller) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = controller.searchController.text.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasSearch
                            ? Icons.search_off_rounded
                            : Icons.people_outline_rounded,
                        size: 40,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      hasSearch
                          ? "لم يتم العثور على مستخدم"
                          : "لا يوجد مستخدمون",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      hasSearch
                          ? "جرّب البحث باستخدام اسم مختلف"
                          : "ابدأ بإضافة أول مستخدم",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    if (hasSearch) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          controller.searchController.clear();
                          controller.load();
                        },
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text("مسح البحث"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(BuildContext context, UsersController controller) {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: colors.onErrorContainer,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "حدث خطأ",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: controller.load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("إعادة المحاولة"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD USER
  // ---------------------------------------------------------------------------

  Future<void> _showUserForm(
    BuildContext context,
    UsersController controller,
  ) async {
    final refresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UserFormBottomSheet(controller: controller),
    );

    if (refresh == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تمت إضافة المستخدم بنجاح")));
    }
  }

  // ---------------------------------------------------------------------------
  // EDIT USER
  // ---------------------------------------------------------------------------

  Future<void> _editUser(
    BuildContext context,
    UsersController controller,
    User user,
  ) async {
    final refresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UserFormBottomSheet(user: user, controller: controller),
    );

    if (refresh == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم تحديث المستخدم بنجاح")));
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE USER
  // ---------------------------------------------------------------------------

  Future<void> _deleteUser(
    BuildContext context,
    UsersController controller,
    User user,
  ) async {
    final balance = controller.balances[user.unified];
    final delete = await showDeleteUserDialog(context, user, balance: balance);

    if (delete != true || !context.mounted) {
      return;
    }

    await controller.deleteUser(user.unified);
  }
}
