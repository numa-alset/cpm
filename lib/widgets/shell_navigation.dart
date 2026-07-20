import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        actions: [
          IconButton(
            onPressed: () {
              // context.push(AppRouter.notificationPath);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          // ThemeToggleButton(),
          // LanguageSwitcher(),
        ],
      ),
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
        return 'المدفوعات';
      case 2:
        return 'المستخدمين';
      case 3:
        return 'المنتجات';
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
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'المنتجات',
        ),
      ],
      onTap: onTap,
    );
  }
}
