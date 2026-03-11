import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/core/network/dio_debug_interceptor.dart';
import 'package:skudyx/core/storage/auth_token_storage.dart';
import 'package:skudyx/features/auth/data/remote/auth_api.dart';
import 'package:skudyx/features/auth/data/social/social/apple_auth_provider.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';
import 'package:skudyx/features/emergency/presentation/controllers/emergency_contact_controller.dart';
import 'package:skudyx/features/profile/controllers/identity_verification_controller.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';
import 'package:skudyx/features/settings/presentation/controllers/notification_prefs_controller.dart';

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
        ChangeNotifierProvider<ProfileController>(
          create: (_) => ProfileController(),
        ),
        ChangeNotifierProvider<NotificationPrefsController>(
          create: (c) =>
              NotificationPrefsController(prefs: c.read<AppPrefs>())..init(),
        ),
        ChangeNotifierProvider<IdentityVerificationController>(
          create: (_) => IdentityVerificationController(),
        ),

        Provider<GoogleAuthProvider>(create: (_) => GoogleAuthProvider()),
        Provider<AppleAuthProvider>(create: (_) => AppleAuthProvider()),

        // Secure storage
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        Provider<AuthTokenStorage>(
          create: (c) => AuthTokenStorage(c.read<FlutterSecureStorage>()),
        ),

        // Dio client
        Provider<Dio>(
          create: (c) {
            final cfg = c.read<AppConfig>();

            final dio = Dio(
              BaseOptions(
                baseUrl: cfg.apiBaseUrl,

                // Increased to tolerate Render cold starts
                connectTimeout: const Duration(seconds: 40),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 40),

                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            );

            // Attach Authorization header
            dio.interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) async {
                  final requiresAuth = options.extra['requiresAuth'] != false;
                  if (requiresAuth) {
                    final token = await c
                        .read<AuthTokenStorage>()
                        .readAccessToken();
                    if (token != null && token.isNotEmpty) {
                      options.headers['Authorization'] = 'Bearer $token';
                    }
                  }
                  handler.next(options);
                },
              ),
            );

            // Safe debug logging + request/response monitoring
            if (kDebugMode) {
              dio.interceptors.add(
                DioDebugInterceptor(
                  maxBodyChars: 12000,
                  logHeaders: true,
                  logRequestBody: true,
                  logResponseBody: true,
                ),
              );
            }

            return dio;
          },
        ),

        // Auth API
        Provider<AuthApi>(create: (c) => AuthApi(dio: c.read<Dio>())),

        // Auth controller
        ChangeNotifierProvider<AuthController>(
          create: (c) => AuthController(
            prefs: c.read<AppPrefs>(),
            tokenStorage: c.read<AuthTokenStorage>(),
            api: c.read<AuthApi>(),
            googleAuthProvider: c.read<GoogleAuthProvider>(),
            appleAuthProvider: c.read<AppleAuthProvider>(),
          )..init(),
        ),

        // Router
        Provider<AppRouter>(
          create: (c) => AppRouter(auth: c.read<AuthController>()),
        ),
      ],
      child: child,
    );
  }
}
