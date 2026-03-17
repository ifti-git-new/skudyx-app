import 'flavors.dart';

class AppConfig {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;

  /// Socket.IO base URL (must be http/https, not ws/wss)
  final String wsUrl;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.wsUrl,
  });

  static String _normalizeSocketIoUrl(String url) {
    // socket_io_client expects http/https base url.
    // If someone sets ws:// or wss://, convert to http/https.
    if (url.startsWith('ws://')) return url.replaceFirst('ws://', 'http://');
    if (url.startsWith('wss://')) return url.replaceFirst('wss://', 'https://');
    return url;
  }

  factory AppConfig.fromEnv() {
    const flavorStr = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

    // API base
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://skudyx-backend-c8do.onrender.com',
    );

    // ✅ Default WS to same host as API (Socket.IO runs on same server)
    const wsUrlRaw = String.fromEnvironment('WS_URL', defaultValue: apiBaseUrl);

    final flavor = flavorFromString(flavorStr);

    return AppConfig(
      flavor: flavor,
      appName: switch (flavor) {
        Flavor.dev => 'SkudyX (Dev)',
        Flavor.staging => 'SkudyX (Staging)',
        Flavor.prod => 'SkudyX',
      },
      apiBaseUrl: apiBaseUrl,
      wsUrl: _normalizeSocketIoUrl(wsUrlRaw),
    );
  }
}
