import 'flavors.dart';

class AppConfig {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String wsUrl;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.wsUrl,
  });

  factory AppConfig.fromEnv() {
    const flavorStr = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.example.com',
    );
    const wsUrl = String.fromEnvironment(
      'WS_URL',
      defaultValue: 'wss://ws.example.com',
    );

    final flavor = flavorFromString(flavorStr);

    return AppConfig(
      flavor: flavor,
      appName: switch (flavor) {
        Flavor.dev => 'SkudyX (Dev)',
        Flavor.staging => 'SkudyX (Staging)',
        Flavor.prod => 'SkudyX',
      },
      apiBaseUrl: apiBaseUrl,
      wsUrl: wsUrl,
    );
  }
}
