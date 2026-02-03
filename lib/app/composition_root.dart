import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/features/auth/data/social/social/apple_auth_provider.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';
import 'package:skudyx/features/emergency/presentation/controllers/emergency_contact_controller.dart';

import '../core/config/app_config.dart';
import '../core/storage/app_prefs.dart';

import '../features/auth/data/social/google_auth_provider.dart';
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
        ChangeNotifierProvider<AppStatusController>(
          create: (c) => AppStatusController(prefs: c.read<AppPrefs>()),
        ),
        ChangeNotifierProvider<DeviceScanController>(
          create: (_) => DeviceScanController(),
        ),
        ChangeNotifierProvider<EmergencyContactController>(
          create: (c) =>
              EmergencyContactController(prefs: c.read<AppPrefs>())..init(),
        ),

        Provider<GoogleAuthProvider>(create: (_) => GoogleAuthProvider()),
        Provider<AppleAuthProvider>(create: (_) => AppleAuthProvider()),

        ChangeNotifierProvider<AuthController>(
          create: (c) => AuthController(
            prefs: c.read<AppPrefs>(),
            googleAuthProvider: c.read<GoogleAuthProvider>(),
            appleAuthProvider: c.read<AppleAuthProvider>(),
          )..init(),
        ),

        ProxyProvider<AuthController, AppRouter>(
          update: (_, auth, __) => AppRouter(auth: auth),
        ),
      ],
      child: child,
    );
  }
}
