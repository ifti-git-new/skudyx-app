import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';

class LiveMediaWebRtcService {
  final CaseAudioRealtimeService audioRealtime;

  LiveMediaWebRtcService({required this.audioRealtime});

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  bool _starting = false;
  bool _started = false;

  // State tracking
  bool micPermissionGranted = false;
  bool cameraPermissionGranted = false;
  bool localStreamAcquired = false;
  bool offerSent = false;
  bool answerReceived = false;
  int sentIceCandidates = 0;
  int receivedIceCandidates = 0;
  String? lastError;
  String signalingState = '-';
  String iceConnectionState = '-';
  String connectionState = '-';

  // Routing IDs
  String? _currentCaseId;
  String? _webSocketId; // ✅ Web's socket ID
  String? _mobileSocketId; // ✅ Mobile's socket ID

  bool get isStarted => _started;
  MediaStream? get localStream => _localStream;
  bool get hasLocalAudioTrack =>
      _localStream?.getAudioTracks().isNotEmpty == true;
  bool get hasLocalVideoTrack => false;

  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  void _log(String message) {
    if (kDebugMode) print(message);
  }

  Future<bool> _ensurePermissions() async {
    _log('🔐 [WebRTC] Requesting microphone...');
    final mic = await Permission.microphone.request();
    micPermissionGranted = mic.isGranted;
    _log('🔐 [WebRTC] Permission: $mic');
    return mic.isGranted;
  }

  /// ✅ Start WebRTC - MATCHES WEB'S SIGNALLING PATTERN
  Future<void> start({
    required String caseId,
    required String webSocketId, // ✅ Web's socket ID (from request_offer)
    void Function(String error)? onError,
    VoidCallback? onStateChanged,
  }) async {
    _log('\n🎥 [WebRTC] start() - case: $caseId, web: $webSocketId');

    if (_starting || _started) {
      _log('⚠️ [WebRTC] Already starting/started');
      return;
    }

    _starting = true;
    _currentCaseId = caseId;
    _webSocketId = webSocketId;
    _mobileSocketId = audioRealtime.socketId;

    offerSent = false;
    answerReceived = false;
    sentIceCandidates = 0;
    receivedIceCandidates = 0;
    localStreamAcquired = false;
    lastError = null;
    signalingState = '-';
    iceConnectionState = '-';
    connectionState = '-';
    onStateChanged?.call();

    try {
      if (_webSocketId == null || _webSocketId!.isEmpty) {
        lastError = 'Web socket ID required';
        _log('❌ [WebRTC] $lastError');
        onError?.call(lastError!);
        _starting = false;
        return;
      }

      final granted = await _ensurePermissions();
      onStateChanged?.call();
      if (!granted) {
        lastError = 'Microphone denied';
        onError?.call(lastError!);
        _starting = false;
        return;
      }

      _log('🎥 [WebRTC] Creating peer connection...');
      _peerConnection = await createPeerConnection(_rtcConfig);

      // ✅ ICE handler - send to web using webSocketId for routing
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
        sentIceCandidates++;
        _log('🧊 [WebRTC] ICE candidate: ${candidate.candidate}');

        if (_webSocketId != null) {
          audioRealtime.emitIceCandidate(
            caseId: caseId,
            candidate: {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
            webSocketId: _webSocketId!, // ✅ Route to web
          );
        }
        onStateChanged?.call();
      };

      _peerConnection!.onConnectionState = (state) {
        connectionState = state.toString();
        _log('🔗 [WebRTC] Connection: $state');
        onStateChanged?.call();
      };

      _peerConnection!.onIceConnectionState = (state) {
        iceConnectionState = state.toString();
        _log('🧊 [WebRTC] ICE: $state');
        onStateChanged?.call();
      };

      _peerConnection!.onSignalingState = (state) {
        signalingState = state.toString();
        _log('📡 [WebRTC] Signaling: $state');
        onStateChanged?.call();
      };

      _log('🎙️ [WebRTC] Getting local stream...');
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      localStreamAcquired = true;
      onStateChanged?.call();

      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      _log('📝 [WebRTC] Creating offer...');
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });
      await _peerConnection!.setLocalDescription(offer);

      offerSent = true;
      onStateChanged?.call();

      _log('📤 [WebRTC] Sending offer to web...');
      // ✅ Emit offer with webSocketId for routing (matches web's expectation)
      audioRealtime.emitOffer(
        caseId: caseId,
        offer: {'sdp': offer.sdp, 'type': offer.type},
        webSocketId: _webSocketId!, // ✅ Web's socket ID for routing
      );

      _started = true;
      onStateChanged?.call();
      _log('✅ [WebRTC] Started successfully');
    } catch (e) {
      lastError = 'WebRTC start failed: $e';
      _log('❌ [WebRTC] $lastError');
      onError?.call(lastError!);
      await stop(onStateChanged: onStateChanged);
    } finally {
      _starting = false;
      onStateChanged?.call();
    }
  }

  /// ✅ Handle answer from Web
  Future<void> handleAnswer(
    dynamic sdpOrAnswer, {
    VoidCallback? onStateChanged,
  }) async {
    _log('\n📥 [WebRTC] handleAnswer()');

    final pc = _peerConnection;
    if (pc == null) {
      _log('❌ [WebRTC] Peer connection not ready');
      return;
    }

    String? sdp;
    String type = 'answer';

    if (sdpOrAnswer is String) {
      sdp = sdpOrAnswer;
    } else if (sdpOrAnswer is Map) {
      sdp = sdpOrAnswer['sdp']?.toString();
      type = sdpOrAnswer['type']?.toString() ?? 'answer';
    }

    if (sdp == null || sdp.isEmpty) {
      lastError = 'Invalid answer';
      _log('❌ [WebRTC] $lastError');
      onStateChanged?.call();
      return;
    }

    _log('📥 [WebRTC] Setting remote description...');
    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    answerReceived = true;

    _log('✅ [WebRTC] Answer set');
    onStateChanged?.call();
  }

  /// ✅ Handle ICE from Web
  Future<void> handleRemoteIceCandidate(
    Map<String, dynamic> data, {
    VoidCallback? onStateChanged,
  }) async {
    _log('\n🧊 [WebRTC] handleRemoteIceCandidate()');

    final pc = _peerConnection;
    if (pc == null) return;

    final candidateStr = data['candidate']?.toString();
    if (candidateStr == null || candidateStr.isEmpty) return;

    final candidate = RTCIceCandidate(
      candidateStr,
      data['sdpMid']?.toString(),
      data['sdpMLineIndex'] is int
          ? data['sdpMLineIndex'] as int
          : int.tryParse('${data['sdpMLineIndex']}'),
    );

    receivedIceCandidates++;
    _log('🧊 [WebRTC] Adding candidate: ${candidate.candidate}');

    await pc.addCandidate(candidate);
    onStateChanged?.call();
  }

  Future<void> stop({VoidCallback? onStateChanged}) async {
    _log('[WebRTC] stop()');
    _started = false;
    _starting = false;

    try {
      await _peerConnection?.close();
    } catch (_) {}
    try {
      final stream = _localStream;
      if (stream != null) {
        for (final track in stream.getTracks()) track.stop();
        await stream.dispose();
      }
    } catch (_) {}

    _peerConnection = null;
    _localStream = null;
    localStreamAcquired = false;
    onStateChanged?.call();
  }

  static bool shouldAutoStartMedia(String caseId) => caseId.startsWith('CL');

  Future<void> dispose() async => await stop();
}
