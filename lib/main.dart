import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/composition_root.dart';
import 'core/config/app_config.dart';
import 'core/storage/app_prefs.dart';

Future<void> main() async {
  await Bootstrap.init();

  final config = AppConfig.fromEnv();
  final prefs = await AppPrefs.create();

  runApp(
    AppCompositionRoot(config: config, prefs: prefs, child: const SkudyXApp()),
  );
}
