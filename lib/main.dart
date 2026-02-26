import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/composition_root.dart';
import 'core/config/app_config.dart';
import 'core/storage/app_prefs.dart';

/// The entry point of the SkudyX application.
Future<void> main() async {
  // 1. Ensure Flutter framework is initialized before any async operations.
  // This prevents potential crashes when calling platform channels (like AppPrefs).
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Bootstrap.init();

    // 3. Initialize configuration and local storage.
    final config = AppConfig.fromEnv();
    final prefs = await AppPrefs.create();

    // 4. Wrap the app in the Composition Root for Dependency Injection.
    runApp(
      AppCompositionRoot(
        config: config,
        prefs: prefs,
        child: const SkudyXApp(),
      ),
    );
  } catch (e) {
    // Basic error handling to catch initialization failures
    debugPrint('Initialization error: $e');
  }
}
