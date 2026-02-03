import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/storage/app_prefs.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import 'router.dart';

class AppCompositionRoot extends StatelessWidget {
  final AppConfig config;
  final AppPrefs prefs;
  final Widget child;

  const AppCompositionRoot({
    super.key,
    required this.config,
    required this.prefs,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<AppPrefs>.value(value: prefs),

        ChangeNotifierProvider<AuthController>(
          create: (c) => AuthController(prefs: c.read<AppPrefs>())..init(),
        ),

        ProxyProvider<AuthController, AppRouter>(
          update: (_, auth, __) => AppRouter(auth: auth),
        ),
      ],
      child: child,
    );
  }
}
