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
//   StreamSubscription<Position>? _positionStreamSub;
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
//     }

//     if (_currentCaseId == null ||
//         _backendBaseUrl == null ||
//         _authToken == null) {
//       _log('❌ Missing data – location tracking disabled');
//       return;
//     }

//     _log('✅ Starting location tracking for case $_currentCaseId');
//     _startLocationStream();
//   }

//   void _startLocationStream() {
//     _positionStreamSub?.cancel();
//     _positionStreamSub =
//         Geolocator.getPositionStream(
//           locationSettings: AndroidSettings(
//             accuracy: LocationAccuracy.bestForNavigation,
//             intervalDuration: const Duration(milliseconds: 500),
//           ),
//         ).listen(
//           (Position pos) async {
//             if (_isUpdating) return;
//             _isUpdating = true;
//             try {
//               await _handlePosition(pos);
//             } catch (e) {
//               // ignore
//             } finally {
//               _isUpdating = false;
//             }
//           },
//           onError: (error) {
//             _log('Position stream error: $error');
//           },
//         );
//     _log('Position stream started');
//   }

//   Future<void> _handlePosition(Position pos) async {
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
//         _log(
//           '📍 Location sent #$_updateCount: ${smoothed.latitude}, ${smoothed.longitude}',
//         );

//         // Forward to UI
//         FlutterForegroundTask.sendDataToMain({
//           'type': 'location_update',
//           'latitude': smoothed.latitude,
//           'longitude': smoothed.longitude,
//         });
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
//     await _positionStreamSub?.cancel();
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
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// File keys for sharing data between main isolate and Android service
const String _tokenFileName = 'fg_token.txt';
const String _caseIdFileName = 'fg_caseid.txt';
const String _baseUrlFileName = 'fg_baseurl.txt';

// ============================================================
// Android Task Handler (runs in a separate isolate)
// ============================================================
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
    _log(
      'Auth token: ${_authToken != null ? "PRESENT (length ${_authToken!.length})" : "NULL"}',
    );

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

        // Forward to main UI
        FlutterForegroundTask.sendDataToMain({
          'type': 'location_update',
          'latitude': smoothed.latitude,
          'longitude': smoothed.longitude,
        });
      } else if (response.statusCode == 401) {
        _log('❌ 401 – token invalid');
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

// ============================================================
// Public Service (handles both Android and iOS)
// ============================================================
class AudioForegroundService {
  AudioForegroundService._();

  static bool _isInitialized = false;
  static bool _isServiceRunning = false;
  static StreamSubscription<Position>? _iosLocationStreamSub;
  static String? _iosCurrentCaseId;
  static String? _iosBackendBaseUrl;
  static String? _iosAuthToken;
  static int _iosUpdateCount = 0;
  static int _iosPositionCount = 0;
  static final List<Position> _iosRecentPositions = [];
  static const int _smoothingWindow = 3;
  static const int _minWarmupPositions = 3;
  static const double _accuracyThreshold = 20.0;

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
    if (Platform.isAndroid) {
      return _startAndroid(caseId, backendBaseUrl, authToken);
    } else if (Platform.isIOS) {
      return _startIOS(caseId, backendBaseUrl, authToken);
    }
    return false;
  }

  static Future<bool> _startAndroid(
    String caseId,
    String backendBaseUrl,
    String authToken,
  ) async {
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

  static Future<bool> _startIOS(
    String caseId,
    String backendBaseUrl,
    String authToken,
  ) async {
    print('🔔 [IOS] _startIOS called for case $caseId');
    _iosCurrentCaseId = caseId;
    _iosBackendBaseUrl = backendBaseUrl;
    _iosAuthToken = authToken;
    _iosUpdateCount = 0;
    _iosPositionCount = 0;
    _iosRecentPositions.clear();

    await _iosRequestPermissions();
    _iosStartLocationStream();
    return true;
  }

  static Future<void> _iosRequestPermissions() async {
    print('🔔 [IOS] Requesting locationAlways permission...');
    final status = await Permission.locationAlways.request();
    print('🔔 [IOS] locationAlways status: $status');
    if (!status.isGranted) {
      print('🔔 [IOS] ❌ Background location permission denied');
    } else {
      print('🔔 [IOS] ✅ Background location permission granted');
    }
  }

  static void _iosStartLocationStream() {
    print('🔔 [IOS] Starting position stream with AppleSettings...');
    _iosLocationStreamSub?.cancel();
    _iosLocationStreamSub =
        Geolocator.getPositionStream(
          locationSettings: AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            pauseLocationUpdatesAutomatically: false,
            activityType: ActivityType.fitness,
            showBackgroundLocationIndicator: true,
          ),
        ).listen(
          (Position pos) async {
            print(
              '🔔 [IOS] Position received: ${pos.latitude}, ${pos.longitude}, accuracy=${pos.accuracy}',
            );
            await _iosHandlePosition(pos);
          },
          onError: (error) {
            print('🔔 [IOS] ❌ Position stream error: $error');
          },
          onDone: () => print('🔔 [IOS] Position stream done'),
        );
    print('🔔 [IOS] Position stream started, waiting for updates...');
  }

  static Future<void> _iosHandlePosition(Position pos) async {
    print('🔔 [IOS] Handling position: ${pos.latitude}, ${pos.longitude}');
    if (_iosCurrentCaseId == null ||
        _iosBackendBaseUrl == null ||
        _iosAuthToken == null) {
      print(
        '🔔 [IOS] Missing data – caseId=$_iosCurrentCaseId, url=$_iosBackendBaseUrl, token=${_iosAuthToken != null}',
      );
      return;
    }

    _iosPositionCount++;
    if (!_iosIsValidPosition(pos)) {
      print(
        '🔔 [IOS] Position invalid (accuracy=${pos.accuracy}, count=$_iosPositionCount)',
      );
      return;
    }

    final smoothed = _iosGetSmoothedPosition(pos);
    if (smoothed == null) {
      print('🔔 [IOS] Not enough positions for smoothing');
      return;
    }

    final url = Uri.parse('$_iosBackendBaseUrl/api/v1/cases/update-location');
    final body = {
      'case_id': _iosCurrentCaseId,
      'latitude': smoothed.latitude,
      'longitude': smoothed.longitude,
    };
    print('🔔 [IOS] Sending location to $url');

    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_iosAuthToken',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _iosUpdateCount++;
        print(
          '🔔 [IOS] ✅ Location sent #$_iosUpdateCount: ${smoothed.latitude}, ${smoothed.longitude}',
        );
        FlutterForegroundTask.sendDataToMain({
          'type': 'location_update',
          'latitude': smoothed.latitude,
          'longitude': smoothed.longitude,
        });
      } else if (response.statusCode == 401) {
        print('🔔 [IOS] ❌ 401 – token invalid');
      } else {
        print('🔔 [IOS] ❌ HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('🔔 [IOS] ❌ HTTP error: $e');
    }
  }

  static bool _iosIsValidPosition(Position pos) {
    if (pos.accuracy > _accuracyThreshold) return false;
    if (pos.latitude == 0 && pos.longitude == 0) return false;
    if (_iosPositionCount < _minWarmupPositions) return false;
    return true;
  }

  static Position? _iosGetSmoothedPosition(Position newPos) {
    _iosRecentPositions.add(newPos);
    if (_iosRecentPositions.length > _smoothingWindow)
      _iosRecentPositions.removeAt(0);
    if (_iosRecentPositions.length < _smoothingWindow) return null;

    double avgLat = 0, avgLon = 0;
    for (final p in _iosRecentPositions) {
      avgLat += p.latitude;
      avgLon += p.longitude;
    }
    avgLat /= _iosRecentPositions.length;
    avgLon /= _iosRecentPositions.length;

    final bestAccuracy = _iosRecentPositions
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

  static Future<void> updateCaseId(String caseId) async {
    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isRunningService) return;
      await _writeToFile(_caseIdFileName, caseId);
      await FlutterForegroundTask.updateService(
        notificationTitle: '🔴 Emergency Active',
        notificationText: 'Audio streaming for case $caseId',
      );
    } else if (Platform.isIOS) {
      _iosCurrentCaseId = caseId;
      print('🔔 [AudioForegroundService] iOS: Updated case ID to $caseId');
    }
  }

  static Future<void> stop() async {
    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.stopService();
      _isServiceRunning = false;
      await _deleteFile(_caseIdFileName);
      await _deleteFile(_baseUrlFileName);
      await _deleteFile(_tokenFileName);
    } else if (Platform.isIOS) {
      await _iosLocationStreamSub?.cancel();
      _iosLocationStreamSub = null;
      _iosCurrentCaseId = null;
    }
    print('🔔 [AudioForegroundService] Service stopped');
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_AudioTaskHandler());
}
