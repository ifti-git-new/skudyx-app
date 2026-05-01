import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:skudyx/core/services/audio_foreground_service.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/composition_root.dart';
import 'core/config/app_config.dart';
import 'core/storage/app_prefs.dart';
import 'core/services/background_service.dart';

/// The entry point of the SkudyX application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AudioForegroundService.initialize();

  try {
    await Bootstrap.init();

    // ✅ Initialize background service early
    // final backgroundService = FlutterBackgroundService();
    // await backgroundService.configure(
    //   androidConfiguration: AndroidConfiguration(
    //     onStart: onStart, // ✅ Use the same top-level function
    //     autoStart: false, // Don't auto-start, we'll start manually
    //     isForegroundMode: true,
    //   ),
    //   iosConfiguration: IosConfiguration(
    //     autoStart: false,
    //     onForeground: onStart,
    //     onBackground: onStart,
    //   ),
    // );

    final config = AppConfig.fromEnv();
    final prefs = await AppPrefs.create();

    runApp(
      AppCompositionRoot(
        config: config,
        prefs: prefs,
        child: const SkudyXApp(),
      ),
    );
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
}
