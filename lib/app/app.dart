import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class SkudyXApp extends StatelessWidget {
  const SkudyXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.read<AppConfig>();
    final router = context.watch<AppRouter>().router;

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
