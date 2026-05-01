// lib/core/services/audio_foreground_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class AudioForegroundService {
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'audio_streaming_channel',
        channelName: 'Live Case Audio',
        channelDescription: 'Keeps audio streaming active during a live case',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    if (kDebugMode) print('✅ [ForegroundService] Initialized');
  }

  static Future<void> start({required String caseId}) async {
    _init();

    try {
      // ✅ FIX: Check notification permission properly
      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission == NotificationPermission.granted) {
        // ✅ FIX: isRunningService is a getter, not a method (no parentheses)
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Live Case Active',
            notificationText: 'Streaming audio for case $caseId',
          );
          if (kDebugMode) print('✅ [ForegroundService] Updated for: $caseId');
          return;
        }

        await FlutterForegroundTask.startService(
          notificationTitle: 'Live Case Active',
          notificationText: 'Streaming audio for case $caseId',
        );

        if (kDebugMode) print('✅ [ForegroundService] Started for: $caseId');
      } else {
        if (kDebugMode)
          print('⚠️ [ForegroundService] Notification permission denied');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [ForegroundService] Start error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      // ✅ FIX: isRunningService is a getter, not a method (no parentheses)
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        if (kDebugMode) print('✅ [ForegroundService] Stopped');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [ForegroundService] Stop error: $e');
    }
  }
}
