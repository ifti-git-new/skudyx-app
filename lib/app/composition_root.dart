import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/config/app_config.dart';
import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/core/network/dio_debug_interceptor.dart';
import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';
import 'package:skudyx/core/realtime/case_realtime_service.dart';
import 'package:skudyx/core/storage/app_prefs.dart';
import 'package:skudyx/core/storage/auth_token_storage.dart';
import 'package:skudyx/features/auth/data/remote/auth_api.dart';
import 'package:skudyx/features/auth/data/social/social/apple_auth_provider.dart';
import 'package:skudyx/features/auth/data/social/google_auth_provider.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_controller.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';
import 'package:skudyx/features/cases/domain/services/websocket_audio_stream_service.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';
import 'package:skudyx/features/device/presentation/controllers/device_session_controller.dart';
import 'package:skudyx/features/emergency/presentation/controllers/emergency_contact_controller.dart';
import 'package:skudyx/features/emergency_contact/data/remote/emergency_contact_api.dart';
import 'package:skudyx/features/profile/controllers/identity_verification_controller.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';
import 'package:skudyx/features/profile/data/remote/profile_api.dart';
import 'package:skudyx/features/profile/data/remote/profile_update_api.dart';
import 'package:skudyx/features/settings/presentation/controllers/notification_prefs_controller.dart';

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
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        Provider<AuthTokenStorage>(
          create: (c) => AuthTokenStorage(c.read<FlutterSecureStorage>()),
        ),
        Provider<Dio>(
          create: (c) {
            final cfg = c.read<AppConfig>();
            final dio = Dio(
              BaseOptions(
                baseUrl: cfg.apiBaseUrl,
                connectTimeout: const Duration(seconds: 40),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 40),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            );
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
        ProxyProvider<Dio, AuthApi>(update: (_, dio, __) => AuthApi(dio: dio)),
        ProxyProvider<Dio, CaseApi>(update: (_, dio, __) => CaseApi(dio: dio)),
        ProxyProvider<Dio, EmergencyContactApi>(
          update: (_, dio, __) => EmergencyContactApi(dio: dio),
        ),
        ProxyProvider<Dio, ProfileApi>(
          update: (_, dio, __) => ProfileApi(dio: dio),
        ),
        ProxyProvider<Dio, ProfileUpdateApi>(
          update: (_, dio, __) => ProfileUpdateApi(dio: dio),
        ),
        ChangeNotifierProvider<AppStatusController>(
          create: (c) => AppStatusController(prefs: c.read<AppPrefs>()),
        ),
        ChangeNotifierProvider<DeviceScanController>(
          create: (_) => DeviceScanController(),
        ),

        // ✅ CaseRealtimeService - no constructor parameters needed
        Provider<CaseRealtimeService>(create: (_) => CaseRealtimeService()),

        // ✅ CORRECT: Pass REQUIRED config and tokenStorage parameters
        Provider<CaseAudioRealtimeService>(
          create: (c) => CaseAudioRealtimeService(
            config: c.read<AppConfig>(),
            tokenStorage: c.read<AuthTokenStorage>(),
          ),
          dispose: (_, svc) => svc.dispose(),
        ),

        // ✅ WebSocket Audio Service Provider
        Provider<WebSocketAudioStreamService>(
          create: (_) => WebSocketAudioStreamService(),
          dispose: (_, svc) => svc.stop(),
        ),

        ChangeNotifierProvider<DeviceSessionController>(
          create: (c) => DeviceSessionController(
            caseApi: c.read<CaseApi>(),
            realtime: c.read<CaseRealtimeService>(),
            audioRealtime: c.read<CaseAudioRealtimeService>(),
            wsAudioService: c.read<WebSocketAudioStreamService>(),
            tokenStorage: c.read<AuthTokenStorage>(), // ✅ add this line
          ),
        ),

        ChangeNotifierProvider<EmergencyContactController>(
          create: (c) => EmergencyContactController(
            prefs: c.read<AppPrefs>(),
            api: c.read<EmergencyContactApi>(),
          )..init(),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (c) => ProfileController(api: c.read<ProfileApi>()),
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
        ChangeNotifierProvider<AuthController>(
          create: (c) => AuthController(
            prefs: c.read<AppPrefs>(),
            tokenStorage: c.read<AuthTokenStorage>(),
            api: c.read<AuthApi>(),
            googleAuthProvider: c.read<GoogleAuthProvider>(),
            appleAuthProvider: c.read<AppleAuthProvider>(),
          )..init(),
        ),
        Provider<AppRouter>(
          create: (c) => AppRouter(auth: c.read<AuthController>()),
        ),
      ],
      child: child,
    );
  }
}
