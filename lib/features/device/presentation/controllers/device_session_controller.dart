import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';
import 'package:skudyx/core/realtime/case_realtime_service.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';
import 'package:skudyx/features/cases/domain/services/live_media_webrtc_service.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';

class DeviceSessionController extends ChangeNotifier {
  // 📦 Dependencies
  final CaseApi caseApi;
  final CaseRealtimeService realtime;
  final CaseAudioRealtimeService audioRealtime;
  final LiveMediaWebRtcService liveMediaWebRtcService;

  DeviceSessionController({
    required this.caseApi,
    required this.realtime,
    required this.audioRealtime,
    required this.liveMediaWebRtcService,
  }) {
    _log('[DeviceSession] Constructor initialized');
    _rtSub = realtime.stream.listen(_onRealtimeUpdate);
    _audioEndedSub = audioRealtime.endedStream.listen(_onAudioEnded);
    _answerSub = audioRealtime.answerStream.listen(_onWebRtcAnswer);
    _iceSub = audioRealtime.iceCandidateStream.listen(_onWebRtcIce);
    _requestOfferSub = audioRealtime.requestOfferStream.listen(
      _onWebRtcRequestOffer,
    );
  }

  // 🔍 Debug Logger
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
  StreamSubscription<WebRtcAnswerEvent>? _answerSub;
  StreamSubscription<WebRtcIceCandidateEvent>? _iceSub;
  StreamSubscription<WebRtcRequestOfferEvent>? _requestOfferSub;

  static const _finalStatuses = {'Resolved', 'Unresolved', 'False'};

  // 🖥️ WebRTC UI Getters
  bool get webrtcMicPermissionGranted =>
      liveMediaWebRtcService.micPermissionGranted;
  bool get webrtcCameraPermissionGranted =>
      liveMediaWebRtcService.cameraPermissionGranted;
  bool get webrtcLocalStreamAcquired =>
      liveMediaWebRtcService.localStreamAcquired;
  bool get webrtcHasLocalAudioTrack =>
      liveMediaWebRtcService.hasLocalAudioTrack;
  bool get webrtcHasLocalVideoTrack =>
      liveMediaWebRtcService.hasLocalVideoTrack;
  bool get webrtcOfferSent => liveMediaWebRtcService.offerSent;
  bool get webrtcAnswerReceived => liveMediaWebRtcService.answerReceived;
  int get webrtcSentIceCandidates => liveMediaWebRtcService.sentIceCandidates;
  int get webrtcReceivedIceCandidates =>
      liveMediaWebRtcService.receivedIceCandidates;
  String get webrtcSignalingState => liveMediaWebRtcService.signalingState;
  String get webrtcIceConnectionState =>
      liveMediaWebRtcService.iceConnectionState;
  String get webrtcConnectionState => liveMediaWebRtcService.connectionState;
  String? get webrtcLastError => liveMediaWebRtcService.lastError;
  MediaStream? get localPreviewStream => liveMediaWebRtcService.localStream;

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

      // 🎯 Handle CL* cases (Live Audio)
      if (LiveMediaWebRtcService.shouldAutoStartMedia(createdCaseId)) {
        _log('\n🎯 [DeviceSession] CL case detected - preparing audio socket');

        await audioRealtime.connectIfNeeded();

        final socketConnected = await _waitForSocket();
        if (socketConnected) {
          _log('✅ [DeviceSession] Socket ready: ${audioRealtime.socketId}');
          await audioRealtime.watchCase(createdCaseId);
          _log('✅ [DeviceSession] Ready for web listeners...');
        } else {
          lastAudioError = 'Socket connection timeout';
          _log('❌ [DeviceSession] Socket failed to connect');
          notifyListeners();
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
      _setError('Failed to start case.');
      _cleanupOnError();
      return false;
    }
  }

  // ⏳ Wait for Socket
  Future<bool> _waitForSocket({int maxAttempts = 20}) async {
    for (int i = 0; i < maxAttempts; i++) {
      if (audioRealtime.isConnected && audioRealtime.socketId != null) {
        _log('✅ [DeviceSession] Socket connected after ${i + 1} attempts');
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
    _log('❌ [DeviceSession] Socket connection timed out');
    return false;
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
    liveMediaWebRtcService.stopAll();
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

  // 🎧 MULTI-LISTENER: Handle WebRTC Events

  /// ✅ Handle incoming request_offer from Web
  Future<void> _onWebRtcRequestOffer(WebRtcRequestOfferEvent event) async {
    _log('\n🎯 [DeviceSession] ════════════════════════════');
    _log('🎯 [DeviceSession] _onWebRtcRequestOffer() CALLED');
    _log('🎯 [DeviceSession] event.caseId: ${event.caseId}');
    _log('🎯 [DeviceSession] event.webSocketId: ${event.webSocketId}');
    _log('🎯 [DeviceSession] this.caseId: $caseId');
    _log('🎯 [DeviceSession] Current listeners: ${_connectedWebUsers.length}');
    _log('🎯 [DeviceSession] ════════════════════════════\n');

    final id = caseId;
    if (id == null || event.caseId != id) {
      _log('⚠️ [DeviceSession] Case mismatch, ignoring');
      return;
    }

    // ✅ Prevent duplicate connections
    if (_connectedWebUsers.contains(event.webSocketId)) {
      _log('⚠️ [DeviceSession] Already connected to ${event.webSocketId}');
      return;
    }

    // ✅ Ensure socket is ready
    if (!audioRealtime.isConnected || audioRealtime.socketId == null) {
      _log('⚠️ [DeviceSession] Socket not connected, reconnecting...');
      await audioRealtime.connectIfNeeded();
      if (!await _waitForSocket()) {
        lastAudioError = 'Socket connection failed';
        _log('❌ [DeviceSession] Socket failed');
        notifyListeners();
        return;
      }
    }

    final mobileSocketId = audioRealtime.socketId;
    if (mobileSocketId == null) {
      lastAudioError = 'Socket ID unavailable';
      _log('❌ [DeviceSession] No socket ID');
      notifyListeners();
      return;
    }

    _log('✅ [DeviceSession] Starting WebRTC for ${event.webSocketId}');

    await liveMediaWebRtcService.startConnection(
      caseId: id,
      webSocketId: event.webSocketId,
      onError: (msg) {
        _log('❌ [DeviceSession] WebRTC error for ${event.webSocketId}: $msg');
        _setMediaError(msg);
      },
      onStateChanged: notifyListeners,
    );

    // ✅ Track successful connection
    if (liveMediaWebRtcService.isConnected(event.webSocketId)) {
      _connectedWebUsers.add(event.webSocketId);
      _log('✅ [DeviceSession] Connected to ${event.webSocketId}');
      _log('✅ [DeviceSession] Total listeners: ${_connectedWebUsers.length}');
      _log('✅ [DeviceSession] Active users: ${_connectedWebUsers.toList()}');
    }

    audioActive = liveMediaWebRtcService.connectionCount > 0;
    notifyListeners();
  }

  /// ✅ Handle answer from specific web user - WITH requesterId FIX
  void _onWebRtcAnswer(WebRtcAnswerEvent event) async {
    _log('\n📥 [DeviceSession] ════════════════════════════');
    _log('📥 [DeviceSession] _onWebRtcAnswer() CALLED');
    _log('📥 [DeviceSession] event.caseId: ${event.caseId}');
    _log('📥 [DeviceSession] event.senderId: ${event.senderId}');
    _log('📥 [DeviceSession] event.requesterId: ${event.requesterId}');
    _log('📥 [DeviceSession] this.caseId: $caseId');
    _log(
      '📥 [DeviceSession] sdpOrAnswer type: ${event.sdpOrAnswer.runtimeType}',
    );
    _log('📥 [DeviceSession] ════════════════════════════\n');

    final id = caseId;
    if (id == null || event.caseId != id) {
      _log('⚠️ [DeviceSession] Case mismatch');
      return;
    }

    // ✅ Use requesterId (web's ID) to find the connection
    // Web sends: sender_id = mobile's ID, requester_id = web's ID
    final webSocketId = event.requesterId ?? event.senderId;

    if (webSocketId == null || webSocketId.isEmpty) {
      _log('⚠️ [DeviceSession] Answer missing webSocketId');
      _log(
        '⚠️ [DeviceSession] Full event: senderId=${event.senderId}, requesterId=${event.requesterId}',
      );
      return;
    }

    _log('📥 [DeviceSession] Routing answer to $webSocketId');
    await liveMediaWebRtcService.handleAnswer(
      webSocketId: webSocketId,
      sdpOrAnswer: event.sdpOrAnswer,
      onStateChanged: notifyListeners,
    );

    _log('✅ [DeviceSession] Answer handled successfully');
  }

  /// ✅ Handle ICE from specific web user
  void _onWebRtcIce(WebRtcIceCandidateEvent event) async {
    _log('\n🧊 [DeviceSession] _onWebRtcIce()');
    _log('🧊 [DeviceSession] caseId: ${event.caseId}');
    _log('🧊 [DeviceSession] webSocketId (senderId): ${event.senderId}');

    final id = caseId;
    if (id == null || event.caseId != id) return;

    final webSocketId = event.senderId;
    if (webSocketId == null || webSocketId.isEmpty) {
      _log('⚠️ [DeviceSession] ICE missing webSocketId');
      return;
    }

    _log('🧊 [DeviceSession] Routing ICE to $webSocketId');
    await liveMediaWebRtcService.handleRemoteIceCandidate(
      webSocketId: webSocketId,
      candidate: event.candidate,
      onStateChanged: notifyListeners,
    );
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
    await liveMediaWebRtcService.stopAll();
    _connectedWebUsers.clear();
    audioActive = false;
    notifyListeners();
  }

  Future<void> _startMediaIfNeeded(String id) async {
    if (!LiveMediaWebRtcService.shouldAutoStartMedia(id)) return;
    if (audioActive) return;
    _log('[DeviceSession] Waiting for web request_offer...');
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
      _setError('Failed to update status.');
      statusUpdating = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _log('[DeviceSession] dispose() called');
    _rtSub?.cancel();
    _audioEndedSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
    _requestOfferSub?.cancel();
    liveMediaWebRtcService.dispose();
    super.dispose();
  }
}
