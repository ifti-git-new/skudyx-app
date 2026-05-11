import 'flavors.dart';

class AppConfig {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String wsUrl; // Socket.IO URL (http/https, not ws/wss)

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.wsUrl,
  });

  static String _normalizeSocketIoUrl(String url) {
    if (url.startsWith('ws://')) return url.replaceFirst('ws://', 'http://');
    if (url.startsWith('wss://')) return url.replaceFirst('wss://', 'https://');
    return url;
  }

  factory AppConfig.fromEnv() {
    const flavorStr = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

    // ✅ FIXED: Use the correct backend URL from logs
    const baseUrl = 'https://skudyx-backend-thtu.onrender.com';

    final flavor = flavorFromString(flavorStr);

    return AppConfig(
      flavor: flavor,
      appName: switch (flavor) {
        Flavor.dev => 'SkudyX (Dev)',
        Flavor.staging => 'SkudyX (Staging)',
        Flavor.prod => 'SkudyX',
      },
      apiBaseUrl: baseUrl,
      wsUrl: _normalizeSocketIoUrl(baseUrl),
    );
  }
}
