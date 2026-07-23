import 'package:go_router/go_router.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/feat/fatora_screen.dart';
import 'package:naji/feat/home_screen.dart';
import 'package:naji/feat/payment_screen.dart';
import 'package:naji/feat/products_screen.dart';
import 'package:naji/feat/register_screen.dart';
import 'package:naji/feat/splash_screen.dart';
import 'package:naji/feat/users/screen/users_screen.dart';
import 'package:naji/widgets/shell_navigation.dart';

final router = GoRouter(
  initialLocation: AppRouter.splashPath,
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
      path: AppRouter.fatoraPath,
      builder: (context, state) => FatoraScreen(),
    ),
    GoRoute(
      path: AppRouter.settingPath,
      builder: (context, state) => FatoraScreen(),
    ),
    GoRoute(
      path: AppRouter.registerPath,
      builder: (context, state) => RegisterScreen(),
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
                return PaymentScreen();
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouter.productsPath,
              builder: (context, state) {
                return ProductsScreen();
              },
            ),
          ],
        ),
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: AppRouter.testPath,
        //       builder: (context, state) {
        //         return CrudScreen();
        //       },
        //     ),
        //   ],
        // ),
      ],
    ),
  ],
);
