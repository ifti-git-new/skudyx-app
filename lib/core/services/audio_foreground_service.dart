// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:skudyx/features/cases/domain/services/websocket_audio_stream_service.dart';

// @pragma('vm:entry-point')
// class _AudioTaskHandler extends TaskHandler {
//   static String? _currentCaseId;

//   static void setCaseId(String? caseId) {
//     _currentCaseId = caseId;
//   }

//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     _log('Task started at $timestamp (starter: ${starter.name})');
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     FlutterForegroundTask.sendDataToMain({'type': 'heartbeat'});
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
//     _log('Task destroyed (isTimeout: $isTimeout)');
//   }

//   @override
//   void onReceiveData(Object data) {
//     _log('Received data: $data');
//   }

//   @override
//   void onNotificationButtonPressed(String id) {
//     _log('Notification button pressed: $id');
//   }

//   @override
//   void onNotificationPressed() {
//     _log('Notification pressed');
//   }

//   @override
//   void onNotificationDismissed() {
//     _log('Notification dismissed');
//   }

//   static void _log(String msg) {
//     if (kDebugMode) print('🔔 [TaskHandler] $msg');
//   }
// }

// class AudioForegroundService {
//   AudioForegroundService._();

//   static WebSocketAudioStreamService? audioService;
//   static bool _isInitialized = false;
//   static bool _isServiceRunning = false;

//   static Future<void> init() async {
//     if (_isInitialized) return;

//     if (Platform.isAndroid) {
//       final status = await Permission.notification.request();
//       if (!status.isGranted) {
//         _log(
//           '❌ Notification permission denied – ongoing notification will not be shown',
//         );
//       }

//       if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
//         await FlutterForegroundTask.requestIgnoreBatteryOptimization();
//       }
//     }

//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'skudyx_audio_channel',
//         channelName: 'Live Audio Streaming',
//         channelDescription: 'Active emergency audio session',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//         onlyAlertOnce: true,
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: true,
//         playSound: false,
//       ),
//       foregroundTaskOptions: ForegroundTaskOptions(
//         eventAction: ForegroundTaskEventAction.repeat(5000),
//         autoRunOnBoot: false,
//         autoRunOnMyPackageReplaced: true,
//         allowWakeLock: true,
//         allowWifiLock: true,
//       ),
//     );

//     _isInitialized = true;
//     _log('Plugin initialized');
//   }

//   static Future<bool> start({required String caseId}) async {
//     if (!Platform.isAndroid) return false;

//     await init();

//     if (await FlutterForegroundTask.isRunningService) {
//       _log('Service is already running – updating case ID');
//       await updateCaseId(caseId);
//       return true;
//     }

//     try {
//       _log('🚀 Starting foreground service for case $caseId');

//       // ✅ CRITICAL: Pass serviceTypes for Android 14+
//       await FlutterForegroundTask.startService(
//         serviceId: 938475,
//         notificationTitle: '🔴 Emergency Active',
//         notificationText: 'Audio streaming for case $caseId',
//         callback: startCallback,
//         serviceTypes: [
//           ForegroundServiceTypes.dataSync,
//           ForegroundServiceTypes.microphone,
//         ],
//       );

//       await Future.delayed(const Duration(milliseconds: 500));
//       _isServiceRunning = await FlutterForegroundTask.isRunningService;

//       if (_isServiceRunning) {
//         _log('✅ Service started successfully');
//       } else {
//         _log('⚠️ Service start failed (service not running after start)');
//       }
//       return _isServiceRunning;
//     } catch (e, stack) {
//       _log('❌ Exception while starting service: $e\n$stack');
//       return false;
//     }
//   }

//   static Future<void> updateCaseId(String caseId) async {
//     if (!Platform.isAndroid) return;
//     if (!await FlutterForegroundTask.isRunningService) return;

//     try {
//       await FlutterForegroundTask.updateService(
//         notificationTitle: '🔴 Emergency Active',
//         notificationText: 'Audio streaming for case $caseId',
//       );
//       _log('Notification updated to case $caseId');
//     } catch (e) {
//       _log('Failed to update notification: $e');
//     }
//   }

//   static Future<void> stop() async {
//     if (!Platform.isAndroid) return;
//     if (!await FlutterForegroundTask.isRunningService) return;

//     await FlutterForegroundTask.stopService();
//     _isServiceRunning = false;
//     _log('Service stopped');
//   }

//   static void _log(String msg) {
//     if (kDebugMode) print('🔔 [AudioForegroundService] $msg');
//   }
// }

// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(_AudioTaskHandler());

// }-----------------------------------....>>>>

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// const String _tokenFileName = 'fg_token.txt';
// const String _caseIdFileName = 'fg_caseid.txt';
// const String _baseUrlFileName = 'fg_baseurl.txt';

// @pragma('vm:entry-point')
// class _AudioTaskHandler extends TaskHandler {
//   Timer? _locationTimer;
//   bool _isUpdating = false;
//   String? _currentCaseId;
//   String? _backendBaseUrl;
//   String? _authToken;

//   int _positionCount = 0;
//   final List<Position> _recentPositions = [];
//   static const int _smoothingWindow = 3;
//   static const int _minWarmupPositions = 3;
//   static const double _accuracyThreshold = 20.0;
//   int _updateCount = 0;

//   Future<String?> _readFromFile(String fileName) async {
//     try {
//       final dir = await getApplicationDocumentsDirectory();
//       final file = File('${dir.path}/$fileName');
//       if (!await file.exists()) return null;
//       return await file.readAsString();
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     _log('Task started with starter: ${starter.name}');

//     _currentCaseId = await _readFromFile(_caseIdFileName);
//     _backendBaseUrl = await _readFromFile(_baseUrlFileName);
//     _authToken = await _readFromFile(_tokenFileName);

//     _log('Case ID: $_currentCaseId');
//     _log('Backend URL: $_backendBaseUrl');
//     if (_authToken == null) {
//       _log('Auth token: NULL');
//     } else {
//       _log('Auth token: PRESENT (length ${_authToken!.length})');
//       _log(
//         'Token preview: ${_authToken!.substring(0, _authToken!.length > 20 ? 20 : _authToken!.length)}...',
//       );
//     }

//     if (_currentCaseId == null ||
//         _backendBaseUrl == null ||
//         _authToken == null) {
//       _log('❌ Missing data – location tracking disabled');
//       return;
//     }

//     _log('✅ Starting location tracking for case $_currentCaseId');
//     _startLocationPolling();
//   }

//   void _startLocationPolling() {
//     _locationTimer?.cancel();
//     _locationTimer = Timer.periodic(const Duration(milliseconds: 500), (
//       _,
//     ) async {
//       if (_isUpdating) return;
//       _isUpdating = true;
//       try {
//         await _updateLocation();
//       } catch (e) {
//         // ignore
//       } finally {
//         _isUpdating = false;
//       }
//     });
//   }

//   Future<void> _updateLocation() async {
//     if (_currentCaseId == null || _backendBaseUrl == null || _authToken == null)
//       return;

//     Position? pos;
//     try {
//       pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.bestForNavigation,
//         timeLimit: const Duration(seconds: 5), // ← increased to 5 seconds
//       );
//     } catch (e) {
//       if (_updateCount % 30 == 0) _log('Failed to get location: $e');
//       return;
//     }

//     _positionCount++;
//     if (!_isValidPosition(pos)) return;

//     final smoothed = _getSmoothedPosition(pos);
//     if (smoothed == null) return;

//     final url = Uri.parse('$_backendBaseUrl/api/v1/cases/update-location');
//     final body = {
//       'case_id': _currentCaseId,
//       'latitude': smoothed.latitude,
//       'longitude': smoothed.longitude,
//     };

//     try {
//       final response = await http
//           .patch(
//             url,
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $_authToken',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         _updateCount++;
//         if (_updateCount % 10 == 0) {
//           _log(
//             '📍 Location sent #$_updateCount: ${smoothed.latitude}, ${smoothed.longitude}',
//           );
//         }
//       } else if (response.statusCode == 401) {
//         _log('Server error: 401');
//       } else {
//         _log('Server error: ${response.statusCode}');
//       }
//     } catch (e) {
//       // silent
//     }
//   }

//   bool _isValidPosition(Position pos) {
//     if (pos.accuracy > _accuracyThreshold) return false;
//     if (pos.latitude == 0 && pos.longitude == 0) return false;
//     if (_positionCount < _minWarmupPositions) return false;
//     return true;
//   }

//   Position? _getSmoothedPosition(Position newPos) {
//     _recentPositions.add(newPos);
//     if (_recentPositions.length > _smoothingWindow)
//       _recentPositions.removeAt(0);
//     if (_recentPositions.length < _smoothingWindow) return null;

//     double avgLat = 0, avgLon = 0;
//     for (final p in _recentPositions) {
//       avgLat += p.latitude;
//       avgLon += p.longitude;
//     }
//     avgLat /= _recentPositions.length;
//     avgLon /= _recentPositions.length;

//     final bestAccuracy = _recentPositions
//         .map((p) => p.accuracy)
//         .reduce((a, b) => a < b ? a : b);

//     return Position(
//       latitude: avgLat,
//       longitude: avgLon,
//       accuracy: bestAccuracy,
//       altitude: newPos.altitude,
//       altitudeAccuracy: newPos.altitudeAccuracy,
//       heading: newPos.heading,
//       headingAccuracy: newPos.headingAccuracy,
//       speed: newPos.speed,
//       speedAccuracy: newPos.speedAccuracy,
//       timestamp: newPos.timestamp,
//       isMocked: newPos.isMocked,
//       floor: newPos.floor,
//     );
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     FlutterForegroundTask.sendDataToMain({'type': 'heartbeat'});
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
//     _locationTimer?.cancel();
//     _log('Task destroyed');
//   }

//   void _log(String msg) {
//     if (kDebugMode) print('🔔 [TaskHandler] $msg');
//   }
// }

// class AudioForegroundService {
//   AudioForegroundService._();

//   static bool _isInitialized = false;
//   static bool _isServiceRunning = false;

//   static Future<void> init() async {
//     if (_isInitialized) return;

//     if (Platform.isAndroid) {
//       final status = await Permission.notification.request();
//       if (!status.isGranted)
//         print('🔔 [AudioForegroundService] ❌ Notification permission denied');
//       if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
//         await FlutterForegroundTask.requestIgnoreBatteryOptimization();
//       }
//     }

//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'skudyx_audio_channel',
//         channelName: 'Live Audio Streaming',
//         channelDescription: 'Active emergency audio session',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//         onlyAlertOnce: true,
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: true,
//         playSound: false,
//       ),
//       foregroundTaskOptions: ForegroundTaskOptions(
//         eventAction: ForegroundTaskEventAction.repeat(5000),
//         autoRunOnBoot: false,
//         autoRunOnMyPackageReplaced: true,
//         allowWakeLock: true,
//         allowWifiLock: true,
//       ),
//     );

//     _isInitialized = true;
//     print('🔔 [AudioForegroundService] Plugin initialized');
//   }

//   static Future<void> _writeToFile(String fileName, String content) async {
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File('${dir.path}/$fileName');
//     await file.writeAsString(content);
//   }

//   static Future<void> _deleteFile(String fileName) async {
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File('${dir.path}/$fileName');
//     if (await file.exists()) await file.delete();
//   }

//   static Future<bool> start({
//     required String caseId,
//     required String backendBaseUrl,
//     required String authToken,
//   }) async {
//     if (!Platform.isAndroid) return false;
//     await init();

//     if (await FlutterForegroundTask.isRunningService) {
//       print(
//         '🔔 [AudioForegroundService] Service already running – updating case',
//       );
//       await updateCaseId(caseId);
//       await _writeToFile(_tokenFileName, authToken);
//       return true;
//     }

//     print(
//       '🔔 [AudioForegroundService] Saving data: caseId=$caseId, token length=${authToken.length}',
//     );
//     await _writeToFile(_caseIdFileName, caseId);
//     await _writeToFile(_baseUrlFileName, backendBaseUrl);
//     await _writeToFile(_tokenFileName, authToken);

//     try {
//       print('🔔 [AudioForegroundService] 🚀 Starting service for case $caseId');
//       await FlutterForegroundTask.startService(
//         serviceId: 938475,
//         notificationTitle: '🔴 Emergency Active',
//         notificationText: 'Audio streaming for case $caseId',
//         callback: startCallback,
//         serviceTypes: [
//           ForegroundServiceTypes.dataSync,
//           ForegroundServiceTypes.microphone,
//           ForegroundServiceTypes.location,
//         ],
//       );

//       await Future.delayed(const Duration(milliseconds: 500));
//       _isServiceRunning = await FlutterForegroundTask.isRunningService;

//       if (_isServiceRunning) {
//         print('🔔 [AudioForegroundService] ✅ Service started successfully');
//       } else {
//         print('🔔 [AudioForegroundService] ⚠️ Service start failed');
//       }
//       return _isServiceRunning;
//     } catch (e, stack) {
//       print('🔔 [AudioForegroundService] ❌ Exception: $e\n$stack');
//       return false;
//     }
//   }

//   static Future<void> updateCaseId(String caseId) async {
//     if (!Platform.isAndroid) return;
//     if (!await FlutterForegroundTask.isRunningService) return;

//     await _writeToFile(_caseIdFileName, caseId);
//     await FlutterForegroundTask.updateService(
//       notificationTitle: '🔴 Emergency Active',
//       notificationText: 'Audio streaming for case $caseId',
//     );
//   }

//   static Future<void> stop() async {
//     if (!Platform.isAndroid) return;
//     if (!await FlutterForegroundTask.isRunningService) return;

//     await FlutterForegroundTask.stopService();
//     _isServiceRunning = false;
//     await _deleteFile(_caseIdFileName);
//     await _deleteFile(_baseUrlFileName);
//     await _deleteFile(_tokenFileName);
//     print('🔔 [AudioForegroundService] Service stopped');
//   }
// }

// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(_AudioTaskHandler());
// }

//-------------------------------....>>>>

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const String _tokenFileName = 'fg_token.txt';
const String _caseIdFileName = 'fg_caseid.txt';
const String _baseUrlFileName = 'fg_baseurl.txt';

@pragma('vm:entry-point')
class _AudioTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStreamSub;
  bool _isUpdating = false;
  String? _currentCaseId;
  String? _backendBaseUrl;
  String? _authToken;

  int _positionCount = 0;
  final List<Position> _recentPositions = [];
  static const int _smoothingWindow = 3;
  static const int _minWarmupPositions = 3;
  static const double _accuracyThreshold = 20.0;
  int _updateCount = 0;

  Future<String?> _readFromFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _log('Task started with starter: ${starter.name}');

    _currentCaseId = await _readFromFile(_caseIdFileName);
    _backendBaseUrl = await _readFromFile(_baseUrlFileName);
    _authToken = await _readFromFile(_tokenFileName);

    _log('Case ID: $_currentCaseId');
    _log('Backend URL: $_backendBaseUrl');
    if (_authToken == null) {
      _log('Auth token: NULL');
    } else {
      _log('Auth token: PRESENT (length ${_authToken!.length})');
    }

    if (_currentCaseId == null ||
        _backendBaseUrl == null ||
        _authToken == null) {
      _log('❌ Missing data – location tracking disabled');
      return;
    }

    _log('✅ Starting location tracking for case $_currentCaseId');
    _startLocationStream();
  }

  void _startLocationStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            intervalDuration: const Duration(milliseconds: 500),
          ),
        ).listen(
          (Position pos) async {
            if (_isUpdating) return;
            _isUpdating = true;
            try {
              await _handlePosition(pos);
            } catch (e) {
              // ignore
            } finally {
              _isUpdating = false;
            }
          },
          onError: (error) {
            _log('Position stream error: $error');
          },
        );
    _log('Position stream started');
  }

  Future<void> _handlePosition(Position pos) async {
    _positionCount++;
    if (!_isValidPosition(pos)) return;

    final smoothed = _getSmoothedPosition(pos);
    if (smoothed == null) return;

    final url = Uri.parse('$_backendBaseUrl/api/v1/cases/update-location');
    final body = {
      'case_id': _currentCaseId,
      'latitude': smoothed.latitude,
      'longitude': smoothed.longitude,
    };

    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _updateCount++;
        _log(
          '📍 Location sent #$_updateCount: ${smoothed.latitude}, ${smoothed.longitude}',
        );

        // Forward to UI
        FlutterForegroundTask.sendDataToMain({
          'type': 'location_update',
          'latitude': smoothed.latitude,
          'longitude': smoothed.longitude,
        });
      } else if (response.statusCode == 401) {
        _log('Server error: 401');
      } else {
        _log('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // silent
    }
  }

  bool _isValidPosition(Position pos) {
    if (pos.accuracy > _accuracyThreshold) return false;
    if (pos.latitude == 0 && pos.longitude == 0) return false;
    if (_positionCount < _minWarmupPositions) return false;
    return true;
  }

  Position? _getSmoothedPosition(Position newPos) {
    _recentPositions.add(newPos);
    if (_recentPositions.length > _smoothingWindow)
      _recentPositions.removeAt(0);
    if (_recentPositions.length < _smoothingWindow) return null;

    double avgLat = 0, avgLon = 0;
    for (final p in _recentPositions) {
      avgLat += p.latitude;
      avgLon += p.longitude;
    }
    avgLat /= _recentPositions.length;
    avgLon /= _recentPositions.length;

    final bestAccuracy = _recentPositions
        .map((p) => p.accuracy)
        .reduce((a, b) => a < b ? a : b);

    return Position(
      latitude: avgLat,
      longitude: avgLon,
      accuracy: bestAccuracy,
      altitude: newPos.altitude,
      altitudeAccuracy: newPos.altitudeAccuracy,
      heading: newPos.heading,
      headingAccuracy: newPos.headingAccuracy,
      speed: newPos.speed,
      speedAccuracy: newPos.speedAccuracy,
      timestamp: newPos.timestamp,
      isMocked: newPos.isMocked,
      floor: newPos.floor,
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.sendDataToMain({'type': 'heartbeat'});
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionStreamSub?.cancel();
    _log('Task destroyed');
  }

  void _log(String msg) {
    if (kDebugMode) print('🔔 [TaskHandler] $msg');
  }
}

class AudioForegroundService {
  AudioForegroundService._();

  static bool _isInitialized = false;
  static bool _isServiceRunning = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted)
        print('🔔 [AudioForegroundService] ❌ Notification permission denied');
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'skudyx_audio_channel',
        channelName: 'Live Audio Streaming',
        channelDescription: 'Active emergency audio session',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;
    print('🔔 [AudioForegroundService] Plugin initialized');
  }

  static Future<void> _writeToFile(String fileName, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
  }

  static Future<void> _deleteFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) await file.delete();
  }

  static Future<bool> start({
    required String caseId,
    required String backendBaseUrl,
    required String authToken,
  }) async {
    if (!Platform.isAndroid) return false;
    await init();

    if (await FlutterForegroundTask.isRunningService) {
      print(
        '🔔 [AudioForegroundService] Service already running – updating case',
      );
      await updateCaseId(caseId);
      await _writeToFile(_tokenFileName, authToken);
      return true;
    }

    print(
      '🔔 [AudioForegroundService] Saving data: caseId=$caseId, token length=${authToken.length}',
    );
    await _writeToFile(_caseIdFileName, caseId);
    await _writeToFile(_baseUrlFileName, backendBaseUrl);
    await _writeToFile(_tokenFileName, authToken);

    try {
      print('🔔 [AudioForegroundService] 🚀 Starting service for case $caseId');
      await FlutterForegroundTask.startService(
        serviceId: 938475,
        notificationTitle: '🔴 Emergency Active',
        notificationText: 'Audio streaming for case $caseId',
        callback: startCallback,
        serviceTypes: [
          ForegroundServiceTypes.dataSync,
          ForegroundServiceTypes.microphone,
          ForegroundServiceTypes.location,
        ],
      );

      await Future.delayed(const Duration(milliseconds: 500));
      _isServiceRunning = await FlutterForegroundTask.isRunningService;

      if (_isServiceRunning) {
        print('🔔 [AudioForegroundService] ✅ Service started successfully');
      } else {
        print('🔔 [AudioForegroundService] ⚠️ Service start failed');
      }
      return _isServiceRunning;
    } catch (e, stack) {
      print('🔔 [AudioForegroundService] ❌ Exception: $e\n$stack');
      return false;
    }
  }

  static Future<void> updateCaseId(String caseId) async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;

    await _writeToFile(_caseIdFileName, caseId);
    await FlutterForegroundTask.updateService(
      notificationTitle: '🔴 Emergency Active',
      notificationText: 'Audio streaming for case $caseId',
    );
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.stopService();
    _isServiceRunning = false;
    await _deleteFile(_caseIdFileName);
    await _deleteFile(_baseUrlFileName);
    await _deleteFile(_tokenFileName);
    print('🔔 [AudioForegroundService] Service stopped');
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_AudioTaskHandler());
}
