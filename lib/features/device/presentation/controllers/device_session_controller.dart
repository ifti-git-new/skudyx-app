import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';
import 'package:skudyx/core/realtime/case_realtime_service.dart';
import 'package:skudyx/core/services/audio_foreground_service.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';
import 'package:skudyx/features/cases/domain/services/websocket_audio_stream_service.dart';
import 'package:skudyx/features/cases/presentation/controllers/live_case_call_controller.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';
import 'package:skudyx/core/config/app_config.dart';

class DeviceSessionController extends ChangeNotifier
    with WidgetsBindingObserver {
  final CaseApi caseApi;
  final CaseRealtimeService realtime;
  final CaseAudioRealtimeService audioRealtime;
  final WebSocketAudioStreamService wsAudioService;

  LiveCaseCallController? _liveCallController;
  LiveCaseCallController? get liveCallController => _liveCallController;

  void setLiveCallController(LiveCaseCallController controller) {
    _liveCallController = controller;
    notifyListeners();
  }

  void clearLiveCallController() {
    _liveCallController?.dispose();
    _liveCallController = null;
    notifyListeners();
  }

  bool _isInBackground = false;
  bool _isScreenOff = false;

  static const Duration _socketConnectTimeout = Duration(seconds: 12);
  static const Duration _apiTimeout = Duration(seconds: 15);
  static const Duration _locationTimeout = Duration(seconds: 12);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  bool _servicesReady = false;
  bool _caseClosing = false;

  DeviceSessionController({
    required this.caseApi,
    required this.realtime,
    required this.audioRealtime,
    required this.wsAudioService,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _log('[DeviceSession] Constructor initialized');

    _rtSub = realtime.stream.listen(_onRealtimeUpdate);
    _audioEndedSub = audioRealtime.endedStream.listen(_onAudioEnded);
    _statusUpdateSub = realtime.statusUpdateStream.listen(_onStatusUpdate);
  }

  void _log(String message) {
    if (kDebugMode) print(message);
  }

  // 📡 Device & Case State
  FoundDevice? connectedDevice;
  bool get isConnected => connectedDevice != null;

  bool starting = false;
  bool tracking = false;
  String? caseId;
  String? caseName;
  String? lastError;
  String? lastStatus;
  String? remotelyClosedStatus;
  bool audioActive = false;
  String? lastAudioError;

  Timer? _timer;
  bool _tickInFlight = false;
  int successUpdates = 0;
  int failedUpdates = 0;
  bool statusUpdating = false;

  final List<Map<String, dynamic>> coordinates = [];
  final Set<String> _connectedWebUsers = {};
  Set<String> get connectedWebUsers => Set.unmodifiable(_connectedWebUsers);
  int get webUserCount => _connectedWebUsers.length;

  StreamSubscription<CaseUpdateEvent>? _rtSub;
  StreamSubscription<AudioStreamEndedEvent>? _audioEndedSub;
  StreamSubscription<CaseUpdateEvent>? _statusUpdateSub;

  static const _finalStatuses = {'Resolved', 'Unresolved', 'False'};

  bool get isWebSocketStreaming => wsAudioService.isStreaming;
  String? get streamingCaseId => wsAudioService.currentCaseId;

  void connectDevice(FoundDevice device) {
    connectedDevice = device;
    notifyListeners();
  }

  Future<void> disconnectDevice() async {
    remotelyClosedStatus = null;
    await stopTracking(clearCase: true);
    connectedDevice = null;
    notifyListeners();
  }

  void clearRemotelyClosedStatus() {
    remotelyClosedStatus = null;
    notifyListeners();
  }

  void _setError(String msg) {
    lastError = msg;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  Future<bool> _ensureServicesReady() async {
    if (_servicesReady) return true;
    _log('🔧 [DeviceSession] Preparing services...');
    try {
      _servicesReady = true;
      _log('✅ [DeviceSession] Services ready');
      return true;
    } catch (e) {
      _log('⚠️ [DeviceSession] Service prep warning: $e');
      _servicesReady = true;
      return true;
    }
  }

  Future<bool> _ensureLocationReady() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _setError('Location services are disabled.');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setError('Location permission denied.');
        return false;
      }
      return true;
    } catch (e) {
      _setError('Failed to check location: $e');
      return false;
    }
  }

  Future<Position> _getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: _locationTimeout,
    );
  }

  Future<bool> _joinRealtimeServicesWithRetry({required String caseId}) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        _log('🔌 [Realtime] Join attempt $attempt/$_maxRetries for: $caseId');

        await realtime
            .watchCase(caseId)
            .timeout(
              _socketConnectTimeout,
              onTimeout: () {
                _log('⚠️ [Realtime] Watch timeout (attempt $attempt)');
              },
            )
            .catchError((e) {
              _log('⚠️ [Realtime] Watch error (attempt $attempt): $e');
            });

        await audioRealtime
            .watchCase(caseId)
            .timeout(
              _socketConnectTimeout,
              onTimeout: () {
                _log('⚠️ [AudioRealtime] Watch timeout (attempt $attempt)');
              },
            )
            .catchError((e) {
              _log('⚠️ [AudioRealtime] Watch error (attempt $attempt): $e');
            });

        _log('✅ [Realtime] Successfully joined: $caseId');
        return true;
      } catch (e) {
        _log('⚠️ [Realtime] Join error (attempt $attempt): $e');
        if (attempt < _maxRetries) {
          _log('🔄 [Realtime] Retrying in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
        }
      }
    }
    _log('❌ [Realtime] Failed to join after $_maxRetries attempts');
    return false;
  }

  // 🚀 Start Case
  Future<bool> startCase({
    required bool isTest,
    required String caseName,
  }) async {
    _log('🚀 [DeviceSession] startCase() CALLED');
    _log('🚀 [DeviceSession] isTest: $isTest, caseName: $caseName');
    _log('🚀 [DeviceSession] isConnected: $isConnected');

    if (!isConnected) {
      _setError('No device connected.');
      return false;
    }

    if (starting || tracking) {
      _log('⚠️ [DeviceSession] Already starting or tracking');
      return false;
    }

    clearError();
    lastAudioError = null;
    audioActive = false;
    _connectedWebUsers.clear();
    _caseClosing = false;

    final ok = await _ensureLocationReady();
    if (!ok) return false;

    bool servicesOk = false;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      servicesOk = await _ensureServicesReady();
      if (servicesOk) break;
      if (attempt < _maxRetries) {
        _log('🔄 [DeviceSession] Retry service init ($attempt/$_maxRetries)');
        await Future.delayed(_retryDelay);
      }
    }
    if (!servicesOk) {
      _log('❌ [DeviceSession] Failed to prepare services');
      return false;
    }

    starting = true;
    tracking = false;
    this.caseName = caseName;
    caseId = null;
    lastStatus = null;
    remotelyClosedStatus = null;
    successUpdates = 0;
    failedUpdates = 0;
    coordinates.clear();
    notifyListeners();

    try {
      _log('📍 [DeviceSession] Getting current position...');
      final firstPos = await _getCurrentPosition();

      _log('📡 [DeviceSession] Creating case on server...');
      final data = await caseApi
          .triggerCase(
            latitude: firstPos.latitude,
            longitude: firstPos.longitude,
            isTest: isTest,
          )
          .timeout(_apiTimeout);

      final createdCaseId = (data['case_id'] ?? '').toString();
      if (createdCaseId.isEmpty) throw Exception('Missing case_id');

      _log('✅ [DeviceSession] Case created: $createdCaseId');
      caseId = createdCaseId;
      lastStatus = (data['status'] ?? 'Pending').toString();

      starting = false;
      tracking = true;
      notifyListeners();

      _log('📡 [DeviceSession] Joining case room via realtime service...');
      final joined = await _joinRealtimeServicesWithRetry(
        caseId: createdCaseId,
      );
      if (!joined) {
        _log(
          '⚠️ [DeviceSession] Realtime join failed, continuing with HTTP fallback...',
        );
      }

      // 🎯 CL* cases — WebSocket audio streaming
      if (createdCaseId.startsWith('CL')) {
        _log('🎯 [DeviceSession] CL case — starting WebSocket audio streaming');
        try {
          await wsAudioService
              .connect(caseId: createdCaseId)
              .timeout(
                _socketConnectTimeout,
                onTimeout: () {
                  _log('⚠️ [WebSocket] Audio connect timeout');
                },
              );

          audioActive = true;
          _log('✅ [DeviceSession] WebSocket audio streaming started');

          // ✅ Start foreground service to keep audio alive in background
          await AudioForegroundService.start(caseId: createdCaseId);
        } catch (e) {
          lastAudioError = 'WebSocket audio failed: $e';
          _log('❌ [DeviceSession] WebSocket audio error: $e');
          notifyListeners();
        }
      }

      await _sendOneTick();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!tracking || _tickInFlight) return;
        _tickInFlight = true;
        try {
          await _sendOneTick();
        } finally {
          _tickInFlight = false;
        }
      });

      _log('✅ [DeviceSession] Location polling started (1s interval)');
      _log('✅ [DeviceSession] startCase() completed successfully');
      return true;
    } on TimeoutException catch (e, stack) {
      _log('❌ [DeviceSession] Timeout error: $e\n$stack');
      _cleanupOnError();
      return false;
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = (resp is Map && resp['message'] != null)
          ? resp['message'].toString()
          : (e.message ?? 'Failed to start case.');
      _setError(msg);
      _log('❌ [DeviceSession] DioException: $msg');
      _cleanupOnError();
      return false;
    } catch (e, stack) {
      _log('❌ [DeviceSession] Unexpected error: $e\n$stack');
      _setError('Failed to start case: $e');
      _cleanupOnError();
      return false;
    }
  }

  // ✅ Handle app lifecycle — screen off, minimize, phone call
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    _log('📱 [DeviceSession] Lifecycle state: $state');

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        _isInBackground = true;
        _log(
          '📱 [DeviceSession] App backgrounded — foreground service should keep audio alive',
        );

        // Optional: Force a quick health check when going background
        if (tracking && caseId != null && wsAudioService.isConnected) {
          try {
            // Send a ping to keep connection warm
            // This is handled by WebSocket service's health check now
          } catch (e) {
            _log('⚠️ [DeviceSession] Background health check failed: $e');
          }
        }
        break;

      case AppLifecycleState.resumed:
        _isInBackground = false;
        _log('📱 [DeviceSession] App resumed — checking audio connection...');

        if (tracking && caseId != null) {
          // ✅ Force reconnection check after resume/call
          // This handles: screen on, app foreground, post-call recovery
          await wsAudioService.resumeIfNeeded();

          // Also refresh foreground service notification
          if (caseId != null) {
            await AudioForegroundService.updateCaseId(caseId!);
          }
        }
        break;

      case AppLifecycleState.hidden:
        // Android-specific: app is hidden but not necessarily paused
        _log('📱 [DeviceSession] App hidden');
        break;
    }
  }

  void _onStatusUpdate(CaseUpdateEvent event) {
    _log('📡 [DeviceSession] _onStatusUpdate() - status: ${event.status}');
    if (_caseClosing) {
      _log('⚠️ [DeviceSession] Already closing, ignoring _onStatusUpdate');
      return;
    }
    lastStatus = event.status;
    if (_finalStatuses.contains(event.status)) {
      _log('🏁 [DeviceSession] Final status via statusUpdate: ${event.status}');
      _closeRemotely(event.status);
      return;
    }
    notifyListeners();
  }

  void _onRealtimeUpdate(CaseUpdateEvent event) async {
    _log('[DeviceSession] _onRealtimeUpdate() - status: ${event.status}');
    final id = caseId;
    if (id == null || event.caseId != id) return;
    if (_caseClosing) {
      _log('⚠️ [DeviceSession] Already closing, ignoring _onRealtimeUpdate');
      return;
    }
    lastStatus = event.status;
    if (_finalStatuses.contains(event.status)) {
      _log(
        '🏁 [DeviceSession] Final status via realtimeUpdate: ${event.status}',
      );
      await _closeRemotely(event.status);
      return;
    }
    notifyListeners();
  }

  // ✅ Single handler for all remote closes
  Future<void> _closeRemotely(String status) async {
    if (_caseClosing) return;
    _caseClosing = true;
    _log('🏁 [DeviceSession] _closeRemotely() status: $status');

    remotelyClosedStatus = status;
    notifyListeners();

    try {
      if (_liveCallController != null) {
        _log('📤 [DeviceSession] Uploading final audio...');
        await _liveCallController!.endCallAndUpload();
        _log('✅ [DeviceSession] Final audio uploaded');
      }
    } catch (e) {
      _log('⚠️ [DeviceSession] Audio upload failed: $e');
    }

    await stopTracking(clearCase: true);
    _caseClosing = false;
  }

  void _cleanupOnError() {
    _log('[DeviceSession] _cleanupOnError() triggered');
    starting = false;
    tracking = false;
    caseId = null;
    caseName = null;
    _timer?.cancel();
    _timer = null;
    realtime.unwatchCase();
    audioRealtime.unwatchCase();
    wsAudioService.stop();
    AudioForegroundService.stop();
    _connectedWebUsers.clear();
    _caseClosing = false;
    notifyListeners();
  }

  Future<void> _sendOneTick() async {
    final id = caseId;
    if (id == null || !tracking) return;

    try {
      final pos = await _getCurrentPosition();

      coordinates.add({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final result = await caseApi
          .updateLocation(
            caseId: id,
            latitude: pos.latitude,
            longitude: pos.longitude,
          )
          .timeout(_apiTimeout);

      successUpdates++;
      if (successUpdates % 10 == 0) {
        _log(
          '[DeviceSession] 📊 Location updates: $successUpdates successful, $failedUpdates failed',
        );
      }

      // ✅ Check status from location update response as HTTP fallback
      final status = result['status']?.toString();
      _log('[DeviceSession] 📍 Tick status from server: $status');

      if (status != null && _finalStatuses.contains(status) && !_caseClosing) {
        _log('🏁 [DeviceSession] Final status detected in tick: $status');
        await _closeRemotely(status);
        return;
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[DeviceSession] location tick failed => $e');
      failedUpdates++;
      notifyListeners();
    }
  }

  void _onAudioEnded(AudioStreamEndedEvent event) async {
    _log('[DeviceSession] _onAudioEnded() - eventCase: ${event.caseId}');
    final id = caseId;
    if (id == null) return;
    if (event.caseId != null && event.caseId != id) return;
    await _stopAudio();
  }

  Future<void> _stopAudio() async {
    _log('[DeviceSession] _stopAudio() called');
    await wsAudioService.stop();
    _connectedWebUsers.clear();
    audioActive = false;
    notifyListeners();
  }

  Future<void> stopTracking({bool clearCase = false}) async {
    _log('[DeviceSession] stopTracking() called, clearCase: $clearCase');

    // ✅ Stop foreground service first
    await AudioForegroundService.stop();

    _timer?.cancel();
    _timer = null;
    _tickInFlight = false;
    starting = false;
    tracking = false;

    await realtime.unwatchCase();
    await audioRealtime.unwatchCase();
    await _stopAudio();

    if (clearCase) {
      clearLiveCallController();
    }

    if (clearCase) {
      caseId = null;
      caseName = null;
      lastStatus = null;
      successUpdates = 0;
      failedUpdates = 0;
      coordinates.clear();
      lastError = null;
      _servicesReady = false;
    }

    notifyListeners();
  }

  Future<bool> updateFinalStatus({
    required String status,
    required String note,
  }) async {
    final id = caseId;
    if (id == null || id.isEmpty) {
      _setError('No active case.');
      return false;
    }
    if (statusUpdating) return false;

    clearError();
    statusUpdating = true;
    notifyListeners();

    try {
      await caseApi
          .updateStatus(caseId: id, status: status, note: note)
          .timeout(_apiTimeout);

      lastStatus = status;
      remotelyClosedStatus = null;

      // ✅ Upload audio on manual close
      try {
        if (_liveCallController != null) {
          _log('📤 [DeviceSession] Uploading final audio on manual close...');
          await _liveCallController!.endCallAndUpload();
        }
      } catch (e) {
        _log('⚠️ [DeviceSession] Audio upload failed on manual close: $e');
      }

      await stopTracking(clearCase: true);
      statusUpdating = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = (resp is Map && resp['message'] != null)
          ? resp['message'].toString()
          : (e.message ?? 'Failed to update status.');
      _setError(msg);
      statusUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _log('[DeviceSession] updateFinalStatus error => $e');
      _setError('Failed to update status: $e');
      statusUpdating = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _statusUpdateSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _log('[DeviceSession] dispose() called');

    _rtSub?.cancel();
    _audioEndedSub?.cancel();

    wsAudioService.dispose();
    AudioForegroundService.stop();
    clearLiveCallController();

    super.dispose();
  }
}
