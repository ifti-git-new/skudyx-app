import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final class Bootstrap {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
