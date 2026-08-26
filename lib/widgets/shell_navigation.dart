import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/router/route_pages.dart';

class ShellNavigation extends StatefulWidget {
  const ShellNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ShellNavigation> createState() => _ShellNavigationState();
}

class _ShellNavigationState extends State<ShellNavigation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(widget.navigationShell.currentIndex)),
        centerTitle: true,
        // actions: [
        // IconButton(
        //   onPressed: () {
        // context.push(AppRouter.notificationPath);
        // },
        // icon: const Icon(Icons.shopping_bag_outlined),
        // ),
        // ThemeToggleButton(),
        // LanguageSwitcher(),
        // ],
      ),
      drawer: AppDrawer(navigationShell: widget.navigationShell),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _switchBranch,
      ),
      body: widget.navigationShell,
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'الجدولة';
      case 1:
        return 'سجل المدفوعات';
      case 2:
        return 'المستخدمين';
      // case 3:
      //   return 'إدارة المنتجات';
      default:
        return 'الجدولة';
    }
  }

  void _switchBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.store, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  "تطبيق ناجي",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('الجدولة'),
            selected: navigationShell.currentIndex == 0,
            onTap: () {
              Navigator.pop(context);
              navigationShell.goBranch(
                0,
                initialLocation: navigationShell.currentIndex == 0,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('سجل المدفوعات'),
            selected: navigationShell.currentIndex == 1,
            onTap: () {
              Navigator.pop(context);
              navigationShell.goBranch(
                1,
                initialLocation: navigationShell.currentIndex == 1,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('المستخدمين'),
            selected: navigationShell.currentIndex == 2,
            onTap: () {
              Navigator.pop(context);
              navigationShell.goBranch(
                2,
                initialLocation: navigationShell.currentIndex == 2,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.stacked_bar_chart),
            title: const Text('الاحصائيات'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.statisticsPath);
            },
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('استيراد البيانات'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.dataManagementPath);
            },
          ),
        ],
      ),
    );
  }
}

class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الجدولة'),
        BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'الدفعات'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'المستخدمين'),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.shopping_cart_outlined),
        //   label: 'المنتجات',
        // ),
      ],
      onTap: onTap,
    );
  }
}
