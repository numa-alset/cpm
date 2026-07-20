import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/locator/locator.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => null,
      child: Builder(
        builder: (context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp.router(
              locale: Locale('ar'),
              supportedLocales: const [Locale('ar')],
              title: "Naji",
              routeInformationProvider:
                  getIt<GoRouter>().routeInformationProvider,
              routeInformationParser: getIt<GoRouter>().routeInformationParser,
              routerDelegate: getIt<GoRouter>().routerDelegate,
              backButtonDispatcher: RootBackButtonDispatcher(),
            ),
          );
        },
      ),
    );
  }
}
