import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';

class LiveMediaWebRtcService {
  final CaseAudioRealtimeService audioRealtime;

  LiveMediaWebRtcService({required this.audioRealtime});

  // ✅ MAP of peer connections (one per web listener)
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _localStreams = {};

  bool _starting = false;

  // ✅ State tracking (global flags) - FIELDS ONLY, NO GETTERS
  bool micPermissionGranted = false;
  bool cameraPermissionGranted = false;
  String? lastError;

  // ✅ Connection-specific state (aggregate for UI)
  int _totalSentIceCandidates = 0;
  int _totalReceivedIceCandidates = 0;
  bool _anyOfferSent = false;
  bool _anyAnswerReceived = false;
  String _aggregateSignalingState = '-';
  String _aggregateIceConnectionState = '-';
  String _aggregateConnectionState = '-';

  // ✅ Getters for UI (DeviceSessionController) - ONLY FOR DERIVED VALUES

  // Local stream info (from first connection, or null)
  MediaStream? get localStream {
    if (_localStreams.isEmpty) return null;
    return _localStreams.values.first;
  }

  bool get localStreamAcquired => _localStreams.isNotEmpty;

  bool get hasLocalAudioTrack {
    final stream = localStream;
    return stream != null && stream.getAudioTracks().isNotEmpty;
  }

  bool get hasLocalVideoTrack {
    final stream = localStream;
    return stream != null && stream.getVideoTracks().isNotEmpty;
  }

  // Signaling state (aggregate from first connection)
  bool get offerSent => _anyOfferSent;
  bool get answerReceived => _anyAnswerReceived;

  int get sentIceCandidates => _totalSentIceCandidates;
  int get receivedIceCandidates => _totalReceivedIceCandidates;

  String get signalingState => _aggregateSignalingState;
  String get iceConnectionState => _aggregateIceConnectionState;
  String get connectionState => _aggregateConnectionState;

  // ✅ Note: lastError, micPermissionGranted, cameraPermissionGranted
  // are already fields, so NO getter needed - Dart auto-generates them

  // Connection count for multi-listener UI
  int get connectionCount => _peerConnections.length;

  void _log(String message) {
    if (kDebugMode) print(message);
  }

  // ✅ Update aggregate state from a specific connection
  void _updateAggregateState(String webSocketId, RTCPeerConnection pc) {
    _aggregateSignalingState = pc.signalingState?.toString() ?? '-';
    _aggregateIceConnectionState = pc.iceConnectionState?.toString() ?? '-';
    _aggregateConnectionState = pc.connectionState?.toString() ?? '-';
  }

  // ✅ Update ICE candidate counters
  void _incrementSentIce() => _totalSentIceCandidates++;
  void _incrementReceivedIce() => _totalReceivedIceCandidates++;

  // ✅ Update offer/answer flags
  void _markOfferSent() => _anyOfferSent = true;
  void _markAnswerReceived() => _anyAnswerReceived = true;

  Future<bool> _ensurePermissions() async {
    _log('🔐 [WebRTC] Requesting microphone...');
    final mic = await Permission.microphone.request();
    micPermissionGranted = mic.isGranted;
    _log('🔐 [WebRTC] Permission: $mic');
    return mic.isGranted;
  }

  /// ✅ START connection for a specific web user
  Future<void> startConnection({
    required String caseId,
    required String webSocketId,
    void Function(String error)? onError,
    VoidCallback? onStateChanged,
  }) async {
    if (_peerConnections.containsKey(webSocketId)) {
      _log('⚠️ [WebRTC] Already connected to $webSocketId');
      return;
    }

    _log('\n🎥 [WebRTC] startConnection() - case: $caseId, web: $webSocketId');
    _log('🎥 [WebRTC] Active connections: ${_peerConnections.length}');

    try {
      if (!micPermissionGranted) {
        final granted = await _ensurePermissions();
        if (!granted) {
          lastError = 'Microphone denied';
          onError?.call(lastError!);
          return;
        }
      }

      _log('🎥 [WebRTC] Creating peer connection for $webSocketId...');

      final pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      });

      _peerConnections[webSocketId] = pc;

      MediaStream? localStream = _localStreams[webSocketId];
      if (localStream == null) {
        _log('🎙️ [WebRTC] Getting local stream...');
        localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        _localStreams[webSocketId] = localStream!;
      }

      for (final track in localStream.getAudioTracks()) {
        await pc.addTrack(track, localStream);
      }

      pc.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
        _incrementSentIce();

        _log('🧊 [WebRTC] ICE for $webSocketId: ${candidate.candidate}');

        audioRealtime.emitIceCandidate(
          caseId: caseId,
          candidate: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
          webSocketId: webSocketId,
        );
      };

      pc.onConnectionState = (state) {
        _updateAggregateState(webSocketId, pc);
        _log('🔗 [WebRTC] Connection $webSocketId: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _log(
            '✅ [WebRTC] Connected to $webSocketId | Total: ${_peerConnections.length}',
          );
        } else if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _removeConnection(webSocketId);
        }
        onStateChanged?.call();
      };

      pc.onIceConnectionState = (state) {
        _updateAggregateState(webSocketId, pc);
        onStateChanged?.call();
      };

      pc.onSignalingState = (state) {
        _updateAggregateState(webSocketId, pc);
        onStateChanged?.call();
      };

      _log('📝 [WebRTC] Creating offer for $webSocketId...');
      final offer = await pc.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });
      await pc.setLocalDescription(offer);
      _markOfferSent();

      _log('📤 [WebRTC] Sending offer to $webSocketId...');
      audioRealtime.emitOffer(
        caseId: caseId,
        offer: {'sdp': offer.sdp, 'type': offer.type},
        webSocketId: webSocketId,
      );

      _log('✅ [WebRTC] Connection started for $webSocketId');
      onStateChanged?.call();
    } catch (e) {
      lastError = 'WebRTC start failed: $e';
      _log('❌ [WebRTC] $lastError');
      onError?.call(lastError!);
      await stopConnection(webSocketId: webSocketId);
    }
  }

  /// ✅ Handle answer from specific web user
  Future<void> handleAnswer({
    required String webSocketId,
    required dynamic sdpOrAnswer,
    VoidCallback? onStateChanged,
  }) async {
    _log('\n📥 [WebRTC] handleAnswer() from $webSocketId');

    final pc = _peerConnections[webSocketId];
    if (pc == null) {
      _log('❌ [WebRTC] No connection for $webSocketId');
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
      _log('❌ [WebRTC] Invalid answer from $webSocketId');
      return;
    }

    _log('📥 [WebRTC] Setting answer from $webSocketId...');
    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    _markAnswerReceived();
    _updateAggregateState(webSocketId, pc);

    _log('✅ [WebRTC] Answer set for $webSocketId');
    onStateChanged?.call();
  }

  /// ✅ Handle ICE from specific web user
  Future<void> handleRemoteIceCandidate({
    required String webSocketId,
    required Map<String, dynamic> candidate,
    VoidCallback? onStateChanged,
  }) async {
    _log('\n🧊 [WebRTC] ICE from $webSocketId');

    final pc = _peerConnections[webSocketId];
    if (pc == null) {
      _log('❌ [WebRTC] No connection for $webSocketId');
      return;
    }

    final candidateStr = candidate['candidate']?.toString();
    if (candidateStr == null || candidateStr.isEmpty) return;

    final iceCandidate = RTCIceCandidate(
      candidateStr,
      candidate['sdpMid']?.toString(),
      candidate['sdpMLineIndex'] is int
          ? candidate['sdpMLineIndex'] as int
          : int.tryParse('${candidate['sdpMLineIndex']}'),
    );

    _incrementReceivedIce();
    _log('🧊 [WebRTC] Adding ICE for $webSocketId: ${iceCandidate.candidate}');
    await pc.addCandidate(iceCandidate);
    onStateChanged?.call();
  }

  /// ✅ Remove specific connection
  void _removeConnection(String webSocketId) {
    _log('🗑️ [WebRTC] Removing connection: $webSocketId');

    final pc = _peerConnections.remove(webSocketId);
    pc?.close();

    final stream = _localStreams.remove(webSocketId);
    stream?.dispose();

    _recalculateAggregates();

    _log(
      '🗑️ [WebRTC] Removed $webSocketId | Remaining: ${_peerConnections.length}',
    );
  }

  /// ✅ Recalculate aggregate state from all active connections
  void _recalculateAggregates() {
    if (_peerConnections.isEmpty) {
      _aggregateSignalingState = '-';
      _aggregateIceConnectionState = '-';
      _aggregateConnectionState = '-';
      return;
    }

    final firstPc = _peerConnections.values.first;
    _aggregateSignalingState = firstPc.signalingState?.toString() ?? '-';
    _aggregateIceConnectionState =
        firstPc.iceConnectionState?.toString() ?? '-';
    _aggregateConnectionState = firstPc.connectionState?.toString() ?? '-';
  }

  /// ✅ Stop connection for specific web user
  Future<void> stopConnection({required String webSocketId}) async {
    _log('⏹️ [WebRTC] Stopping connection: $webSocketId');
    _removeConnection(webSocketId);
  }

  /// ✅ Stop ALL connections
  Future<void> stopAll() async {
    _log('⏹️ [WebRTC] Stopping all connections...');

    final webSocketIds = List<String>.from(_peerConnections.keys);
    for (final id in webSocketIds) {
      await stopConnection(webSocketId: id);
    }

    _totalSentIceCandidates = 0;
    _totalReceivedIceCandidates = 0;
    _anyOfferSent = false;
    _anyAnswerReceived = false;
    _aggregateSignalingState = '-';
    _aggregateIceConnectionState = '-';
    _aggregateConnectionState = '-';

    _log('✅ [WebRTC] All connections stopped');
  }

  /// ✅ Get connection status for specific web user
  bool isConnected(String webSocketId) {
    return _peerConnections.containsKey(webSocketId);
  }

  /// ✅ Get all connected web users
  List<String> getConnectedUsers() {
    return _peerConnections.keys.toList();
  }

  Future<void> dispose() async {
    await stopAll();
  }

  static bool shouldAutoStartMedia(String caseId) => caseId.startsWith('CL');
}
