// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// class AudioForegroundService {
//   static bool _initialized = false;
//   static String? _currentCaseId;

//   static void initialize() {
//     _init();
//   }

//   static void _init() {
//     if (_initialized) return;
//     _initialized = true;
//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'audio_streaming_channel',
//         channelName: 'Live Case Audio',
//         channelDescription: 'Keeps audio streaming active during a live case',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: true,
//         playSound: false,
//       ),
//       foregroundTaskOptions: ForegroundTaskOptions(
//         eventAction: ForegroundTaskEventAction.nothing(),
//         autoRunOnBoot: false,
//         allowWakeLock: true,
//         allowWifiLock: true,
//       ),
//     );
//     if (kDebugMode) print('✅ [ForegroundService] Initialized');
//   }

//   static Future<void> start({required String caseId}) async {
//     _init();
//     _currentCaseId = caseId;

//     try {
//       final isRunning = await FlutterForegroundTask.isRunningService;

//       if (isRunning) {
//         await FlutterForegroundTask.updateService(
//           notificationTitle: 'Live Case Active',
//           notificationText: 'Streaming audio for case #$caseId',
//         );
//         if (kDebugMode) print('✅ [ForegroundService] Updated for: $caseId');
//         return;
//       }

//       await FlutterForegroundTask.startService(
//         notificationTitle: 'Live Case Active',
//         notificationText: 'Streaming audio for case #$caseId',
//       );

//       if (kDebugMode) print('✅ [ForegroundService] Started for: $caseId');
//     } catch (e, stack) {
//       if (kDebugMode) {
//         print('⚠️ [ForegroundService] Start error: $e');
//         print('Stack: $stack');
//       }
//       // Don't crash - audio can still work without foreground service
//     }
//   }

//   static Future<void> updateCaseId(String caseId) async {
//     _currentCaseId = caseId;
//     if (await FlutterForegroundTask.isRunningService) {
//       await FlutterForegroundTask.updateService(
//         notificationTitle: 'Live Case Active',
//         notificationText: 'Streaming audio for case #$caseId',
//       );
//     }
//   }

//   static Future<void> stop() async {
//     try {
//       final isRunning = await FlutterForegroundTask.isRunningService;
//       if (isRunning) {
//         await FlutterForegroundTask.stopService();
//         if (kDebugMode) print('✅ [ForegroundService] Stopped');
//       }
//     } catch (e) {
//       if (kDebugMode) print('⚠️ [ForegroundService] Stop error: $e');
//     }
//     _currentCaseId = null;
//   }

//   static String? get currentCaseId => _currentCaseId;
// }

// // ✅ Required: TaskHandler for foreground task events (flutter_foreground_task v9+)
// class _ForegroundTaskHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     if (kDebugMode) print('🔋 [ForegroundTask] onStart');
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     // Optional: periodic heartbeat
//     if (kDebugMode) print('💓 [ForegroundTask] Heartbeat');
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp, bool isTaskRemoved) async {
//     if (kDebugMode)
//       print('🔋 [ForegroundTask] onDestroy - removed: $isTaskRemoved');
//     // Clean up resources if needed
//   }

//   @override
//   void onNotificationButtonPressed(String id) {
//     // Handle button taps if you add buttons later
//   }

//   @override
//   void onNotificationPressed() {
//     // Bring app to foreground when notification tapped
//     FlutterForegroundTask.launchApp();
//   }

//   @override
//   void onNotificationDismissed() {
//     // Optional: handle dismissal
//   }
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:skudyx/features/cases/domain/services/websocket_audio_stream_service.dart';

class AudioForegroundService {
  static bool _initialized = false;
  static String? _currentCaseId;

  // ✅ Public static reference – used by the foreground task handler to keep the microphone alive
  static WebSocketAudioStreamService? audioService;

  static void initialize() {
    _init();
  }

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
        allowWakeLock: true, // ✅ keep CPU alive
        allowWifiLock: true, // ✅ keep Wi‑Fi alive
      ),
    );

    // ✅ Register the handler so the foreground service stays alive
    FlutterForegroundTask.setTaskHandler(_ForegroundTaskHandler());

    if (kDebugMode) print('✅ [ForegroundService] Initialized');
  }

  static Future<void> start({required String caseId}) async {
    _init();
    _currentCaseId = caseId;

    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Live Case Active',
          notificationText: 'Streaming audio for case #$caseId',
        );
        if (kDebugMode) print('✅ [ForegroundService] Updated for: $caseId');
        return;
      }

      await FlutterForegroundTask.startService(
        notificationTitle: 'Live Case Active',
        notificationText: 'Streaming audio for case #$caseId',
      );
      if (kDebugMode) print('✅ [ForegroundService] Started for: $caseId');
    } catch (e, stack) {
      if (kDebugMode) {
        print('⚠️ [ForegroundService] Start error: $e');
        print('Stack: $stack');
      }
    }
  }

  static Future<void> updateCaseId(String caseId) async {
    _currentCaseId = caseId;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Live Case Active',
        notificationText: 'Streaming audio for case #$caseId',
      );
    }
  }

  static Future<void> stop() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        if (kDebugMode) print('✅ [ForegroundService] Stopped');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [ForegroundService] Stop error: $e');
    }
    _currentCaseId = null;
  }

  static String? get currentCaseId => _currentCaseId;
}

// ✅ Required: TaskHandler for foreground task events
class _ForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (kDebugMode) print('🔋 [ForegroundTask] onStart');

    // ✅ Ensure the notification is updated and wake locks are active.
    // This is especially important on devices that may clear the notification or release wake locks.
    final caseId = AudioForegroundService.currentCaseId;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Live Case Active',
      notificationText: caseId != null
          ? 'Streaming audio for case #$caseId'
          : 'Audio service running',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // ✅ Keep the microphone alive – restart recording if it has been killed
    if (AudioForegroundService.audioService != null &&
        !AudioForegroundService.audioService!.isStreaming) {
      if (kDebugMode) print('🔁 [ForegroundTask] Restarting idle audio…');
      await AudioForegroundService.audioService!.resumeIfNeeded();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTaskRemoved) async {
    if (kDebugMode)
      print('🔋 [ForegroundTask] onDestroy - removed: $isTaskRemoved');
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}
