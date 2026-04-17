import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  String caseId = 'unknown';
  bool _isServiceRunning = true;

  // Listen for caseId being set
  service.on('setCaseId').listen((event) {
    // ✅ FIX: Add null check for event
    if (event != null && event is Map && event['caseId'] != null) {
      caseId = event['caseId'] as String;
      if (kDebugMode) {
        print('🔋 [BackgroundService] Received caseId: $caseId');
      }
    }
  });

  if (kDebugMode) {
    print('🔋 [BackgroundService] Running in background for case: $caseId');
  }

  // Only for Android - keep service as foreground
  if (service is AndroidServiceInstance) {
    try {
      await service.setAsForegroundService();
      if (kDebugMode) {
        print('🔋 [BackgroundService] Set as foreground service');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [BackgroundService] Foreground service error: $e');
      }
    }
  }

  // Keep service alive with periodic updates
  Timer.periodic(const Duration(seconds: 30), (timer) {
    if (!_isServiceRunning) {
      timer.cancel();
      return;
    }
    // Send heartbeat to keep service alive
    service.invoke('heartbeat', {
      'caseId': caseId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  // Listen for stop command
  service.on('stop').listen((event) {
    _isServiceRunning = false;
    service.stopSelf();
  });

  // ✅ Return true to indicate successful initialization
  return true;
}

class BackgroundServiceManager {
  static final _instance = BackgroundServiceManager._();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._();

  final _service = FlutterBackgroundService();
  bool _isRunning = false;
  bool _isConfigured = false;

  // Start foreground service for background audio/location
  Future<void> start({required String caseId}) async {
    if (_isRunning) return;

    // ✅ FIX: Only configure once
    if (!_isConfigured) {
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          // ✅ Use top-level onStart function
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          // ✅ Notification config
          notificationChannelId: 'skudyx_emergency',
          initialNotificationTitle: 'SkudyX Emergency Active',
          initialNotificationContent: 'Tracking location and streaming audio',
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onStart,
        ),
      );
      _isConfigured = true;
    }

    // Start the service with caseId
    await _service.startService();
    _service.invoke('setCaseId', {'caseId': caseId});
    _isRunning = true;

    if (kDebugMode) print('🔋 [BackgroundService] Started for case: $caseId');
  }

  // Stop foreground service
  Future<void> stop() async {
    if (!_isRunning) return;

    // Stop the service
    _service.invoke('stop');
    _isRunning = false;

    if (kDebugMode) print('🔋 [BackgroundService] Stopped');
  }

  bool get isRunning => _isRunning;
}
