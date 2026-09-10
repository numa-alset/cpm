import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/feat/data_management/screen/data_management_screen.dart';
import 'package:naji/feat/error_screen.dart';
import 'package:naji/feat/home/screen/home_screen.dart';
import 'package:naji/feat/invoices/screen/invoices_screen.dart';
import 'package:naji/feat/payments/screen/payments_screen.dart';
import 'package:naji/feat/register_screen.dart';
import 'package:naji/feat/splash_screen.dart';
import 'package:naji/feat/statistics/screen/statistics_screen.dart';
import 'package:naji/feat/users/screen/add_invoice_screen.dart';
import 'package:naji/feat/users/screen/add_payment_screen.dart';
import 'package:naji/feat/users/screen/user_details_screen.dart';
import 'package:naji/feat/users/screen/users_screen.dart';
import 'package:naji/widgets/shell_navigation.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRouter.splashPath,
  onException: (context, state, router) {
    final location = state.uri.toString();

    // If it's a file share intent, silently go to the home screen
    if (location.startsWith('content://') || location.startsWith('file://')) {
      router.go(AppRouter.homePath);
    } else {
      // Handle actual unknown routes (e.g., show a 404 page)
      router.go(AppRouter.errorPath);
    }
  },
  routes: [
    GoRoute(
      redirect: (context, state) async {
        final hasDeviceId = await DeviceService().hasDeviceId();
        if (hasDeviceId) {
          return AppRouter.homePath;
        }
        return AppRouter.registerPath;
      },
      path: AppRouter.splashPath,
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: AppRouter.errorPath,
      builder: (context, state) {
        return const ErrorScreen(
          title: 'صفحة غير موجودة',
          message: 'عذراً، المسار الذي تحاول الوصول إليه غير موجود.',
          showDataManagementButton:
              true, // Shows the "Home" button from your custom widget
        );
      },
    ),
    GoRoute(
      path: AppRouter.registerPath,
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: AppRouter.statisticsPath,
      builder: (context, state) => StatisticScreen(),
    ),
    GoRoute(
      path: AppRouter.dataManagementPath,
      builder: (context, state) => DataManagementScreen(),
    ),
    GoRoute(
      path: AppRouter.userDetailsPath,
      builder: (context, state) {
        final userUuid = state.extra as String;
        return UserDetailsScreen(userUuid: userUuid);
      },
    ),
    GoRoute(
      path: AppRouter.fatoraPath,
      builder: (context, state) {
        return InvoicesScreen();
      },
    ),
    GoRoute(
      path: AppRouter.addPaymentPath,
      builder: (context, state) {
        final userUuid = state.extra as String;
        return AddPaymentScreen(userUnified: userUuid);
      },
    ),
    GoRoute(
      path: AppRouter.addInvoicePath,
      builder: (context, state) {
        final userUuid = state.extra as String;
        return AddInvoiceScreen(userUnified: userUuid);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellNavigation(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.homePath,
              builder: (context, state) {
                return HomeScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.paymentPath,
              builder: (context, state) {
                return PaymentsScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.productsPath,
              builder: (context, state) {
                return InvoicesScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.usersPath,
              builder: (context, state) {
                return UsersScreen();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
