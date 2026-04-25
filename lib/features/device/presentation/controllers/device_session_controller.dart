import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';
import 'package:skudyx/core/realtime/case_realtime_service.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';
import 'package:skudyx/features/cases/domain/services/websocket_audio_stream_service.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';

class DeviceSessionController extends ChangeNotifier
    with WidgetsBindingObserver {
  final CaseApi caseApi;
  final CaseRealtimeService realtime;
  final CaseAudioRealtimeService audioRealtime;
  final WebSocketAudioStreamService wsAudioService;

  bool _isInBackground = false;

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

  // 🎧 Multi-Listener Tracking
  final Set<String> _connectedWebUsers = {};
  Set<String> get connectedWebUsers => Set.unmodifiable(_connectedWebUsers);
  int get webUserCount => _connectedWebUsers.length;

  // 📜 Stream Subscriptions
  StreamSubscription<CaseUpdateEvent>? _rtSub;
  StreamSubscription<AudioStreamEndedEvent>? _audioEndedSub;
  StreamSubscription<CaseUpdateEvent>? _statusUpdateSub;

  static const _finalStatuses = {'Resolved', 'Unresolved', 'False'};

  // ✅ WebSocket Audio Getters
  bool get isWebSocketStreaming => wsAudioService.isStreaming;
  String? get streamingCaseId => wsAudioService.currentCaseId;

  // 🔌 Device Management
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

  void _setMediaError(String msg) {
    lastAudioError = msg;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  // 📍 Location Helpers
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
      timeLimit: const Duration(seconds: 10),
    );
  }

  // 🚀 Start Case
  Future<bool> startCase({
    required bool isTest,
    required String caseName,
  }) async {
    _log('\n🚀 [DeviceSession] startCase() CALLED');
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

    final ok = await _ensureLocationReady();
    if (!ok) return false;

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
      final firstPos = await _getCurrentPosition();
      _log('📡 [DeviceSession] Creating case on server...');

      final data = await caseApi.triggerCase(
        latitude: firstPos.latitude,
        longitude: firstPos.longitude,
        isTest: isTest,
      );

      final createdCaseId = (data['case_id'] ?? '').toString();
      if (createdCaseId.isEmpty) throw Exception('Missing case_id');

      _log('✅ [DeviceSession] Case created: $createdCaseId');
      caseId = createdCaseId;
      lastStatus = (data['status'] ?? 'Pending').toString();

      starting = false;
      tracking = true;
      notifyListeners();

      _log('📡 [DeviceSession] Joining case room via realtime service...');
      await realtime.watchCase(createdCaseId);

      // 🎯 Handle CL* cases (Live Audio via WebSocket)
      if (createdCaseId.startsWith('CL')) {
        _log(
          '\n🎯 [DeviceSession] CL case detected - starting WebSocket audio streaming',
        );

        try {
          await wsAudioService.connect(caseId: createdCaseId);
          audioActive = true;
          _log('✅ [DeviceSession] WebSocket audio streaming started');
        } catch (e) {
          lastAudioError = 'WebSocket audio failed: $e';
          _log('❌ [DeviceSession] WebSocket audio error: $e');
          notifyListeners();
          // Continue even if audio fails - location tracking still works
        }
      }

      await _sendOneTick();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!tracking || _tickInFlight) return;
        _tickInFlight = true;
        try {
          await _sendOneTick();
        } finally {
          _tickInFlight = false;
        }
      });

      _log('✅ [DeviceSession] startCase() completed successfully');
      return true;
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = (resp is Map && resp['message'] != null)
          ? resp['message'].toString()
          : (e.message ?? 'Failed to start case.');
      _setError(msg);
      _log('❌ [DeviceSession] DioException: $msg');
      _cleanupOnError();
      return false;
    } catch (e) {
      _log('❌ [DeviceSession] Unexpected error: $e');
      _setError('Failed to start case: $e');
      _cleanupOnError();
      return false;
    }
  }

  // ✅ Handle app lifecycle changes for background execution
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isInBackground = true;
      _log(
        '📱 [DeviceSession] App paused - WebSocket audio continues streaming',
      );
      // WebSocket should continue in background on most platforms
    } else if (state == AppLifecycleState.resumed) {
      _isInBackground = false;
      _log('📱 [DeviceSession] App resumed - checking connection...');
      // Reconnect WebSocket if needed
      if (tracking &&
          caseId?.startsWith('CL') == true &&
          !wsAudioService.isConnected) {
        _log('🔄 [DeviceSession] Reconnecting WebSocket after resume...');
        wsAudioService.connect(caseId: caseId!).catchError((e) {
          _log('❌ [DeviceSession] Reconnect failed: $e');
        });
      }
    }
  }

  // ✅ Handle real-time status updates from web
  void _onStatusUpdate(CaseUpdateEvent event) {
    _log('📡 [DeviceSession] Received status update: ${event.status}');

    // Update local state
    lastStatus = event.status;

    // If case is resolved/unresolved/false, stop tracking
    if (_finalStatuses.contains(event.status)) {
      remotelyClosedStatus = event.status;
      _log('🏁 [DeviceSession] Case closed remotely: ${event.status}');
      stopTracking(clearCase: true);
    }

    notifyListeners();
  }

  // 🧹 Cleanup
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
    _connectedWebUsers.clear();
    notifyListeners();
  }

  // 📍 Location Tick
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
      await caseApi.updateLocation(
        caseId: id,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      successUpdates++;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[DeviceSession] location tick failed => $e');
      failedUpdates++;
      notifyListeners();
    }
  }

  /// ✅ Handle realtime case updates
  void _onRealtimeUpdate(CaseUpdateEvent event) async {
    _log('[DeviceSession] _onRealtimeUpdate() - status: ${event.status}');
    final id = caseId;
    if (id == null || event.caseId != id) return;

    lastStatus = event.status;

    if (_finalStatuses.contains(event.status)) {
      remotelyClosedStatus = event.status;
      _log('🏁 [DeviceSession] Case closed: ${event.status}');
      await stopTracking(clearCase: true);
      return;
    }
    notifyListeners();
  }

  /// ✅ Handle audio stream ended
  void _onAudioEnded(AudioStreamEndedEvent event) async {
    _log('[DeviceSession] _onAudioEnded() - eventCase: ${event.caseId}');
    final id = caseId;
    if (id == null) return;
    if (event.caseId != null && event.caseId != id) return;
    await _stopAudio();
  }

  // 🛑 Stop Audio & Tracking
  Future<void> _stopAudio() async {
    _log('[DeviceSession] _stopAudio() called');
    await wsAudioService.stop();
    _connectedWebUsers.clear();
    audioActive = false;
    notifyListeners();
  }

  Future<void> stopTracking({bool clearCase = false}) async {
    _log('[DeviceSession] stopTracking() called, clearCase: $clearCase');

    _timer?.cancel();
    _timer = null;
    _tickInFlight = false;
    starting = false;
    tracking = false;

    await realtime.unwatchCase();
    await audioRealtime.unwatchCase();
    await _stopAudio();

    if (clearCase) {
      caseId = null;
      caseName = null;
      lastStatus = null;
      successUpdates = 0;
      failedUpdates = 0;
      coordinates.clear();
      lastError = null;
    }
    notifyListeners();
  }

  // 🏁 Update Final Status
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
      await caseApi.updateStatus(caseId: id, status: status, note: note);
      lastStatus = status;
      remotelyClosedStatus = null;
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
    super.dispose();
  }
}
