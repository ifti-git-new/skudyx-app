// [WEBRTC] This file is kept for future use but not currently active
// To re-enable WebRTC: uncomment this file and update dependencies in other files

/*
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';
import 'package:dio/dio.dart';

class LiveMediaWebRtcService {
  final CaseAudioRealtimeService audioRealtime;

  LiveMediaWebRtcService({required this.audioRealtime});

  // ✅ MAP of peer connections (one per web listener)
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _localStreams = {};

  bool _starting = false;

  // ✅ State tracking (global flags)
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

  // ✅ Getters for UI (DeviceSessionController)
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
  bool get offerSent => _anyOfferSent;
  bool get answerReceived => _anyAnswerReceived;
  int get sentIceCandidates => _totalSentIceCandidates;
  int get receivedIceCandidates => _totalReceivedIceCandidates;
  String get signalingState => _aggregateSignalingState;
  String get iceConnectionState => _aggregateIceConnectionState;
  String get connectionState => _aggregateConnectionState;
  int get connectionCount => _peerConnections.length;

  void _log(String message) {
    if (kDebugMode) print(message);
  }

  // ✅ METERED.CA API CONFIGURATION
  static const String _meteredApiKey = 'a1b48b5a958e1938011d61c68523957fb046';
  static const String _meteredApiUrl =
      'https://technovicinity.metered.live/api/v1/turn/credentials';
  static Map<String, dynamic>? _cachedIceConfig;
  static DateTime? _cacheExpiry;
  static const Duration _cacheDuration = Duration(hours: 1);

  Future<Map<String, dynamic>> _fetchIceConfig() async {
    if (_cachedIceConfig != null &&
        _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _cachedIceConfig!;
    }
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.get(
        _meteredApiUrl,
        queryParameters: {'apiKey': _meteredApiKey},
      );
      if (response.statusCode == 200 && response.data != null) {
        final iceServers = response.data as List;
        final config = {
          'iceServers': iceServers,
          'iceTransportPolicy': 'all',
          'sdpSemantics': 'unified-plan',
        };
        _cachedIceConfig = config;
        _cacheExpiry = DateTime.now().add(_cacheDuration);
        return config;
      } else {
        throw Exception('Metered API returned ${response.statusCode}');
      }
    } catch (e) {
      return _getFallbackIceConfig();
    }
  }

  Map<String, dynamic> _getFallbackIceConfig() {
    return {
      'iceServers': [
        {'urls': 'stun:stun.relay.metered.ca:80'},
        {
          'urls': 'turn:global.relay.metered.ca:80',
          'username': 'df26db12af78868b586443f3',
          'credential': 'ukv5zU21oQZfuEQX',
        },
        {
          'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
          'username': 'df26db12af78868b586443f3',
          'credential': 'ukv5zU21oQZfuEQX',
        },
        {
          'urls': 'turn:global.relay.metered.ca:443',
          'username': 'df26db12af78868b586443f3',
          'credential': 'ukv5zU21oQZfuEQX',
        },
        {
          'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
          'username': 'df26db12af78868b586443f3',
          'credential': 'ukv5zU21oQZfuEQX',
        },
      ],
      'iceTransportPolicy': 'all',
      'sdpSemantics': 'unified-plan',
    };
  }

  void _updateAggregateState(String webSocketId, RTCPeerConnection pc) {
    _aggregateSignalingState = pc.signalingState?.toString() ?? '-';
    _aggregateIceConnectionState = pc.iceConnectionState?.toString() ?? '-';
    _aggregateConnectionState = pc.connectionState?.toString() ?? '-';
  }

  void _incrementSentIce() => _totalSentIceCandidates++;
  void _incrementReceivedIce() => _totalReceivedIceCandidates++;
  void _markOfferSent() => _anyOfferSent = true;
  void _markAnswerReceived() => _anyAnswerReceived = true;

  Future<bool> _ensurePermissions() async {
    final mic = await Permission.microphone.request();
    micPermissionGranted = mic.isGranted;
    return mic.isGranted;
  }

  Future<void> startConnection({
    required String caseId,
    required String webSocketId,
    void Function(String error)? onError,
    VoidCallback? onStateChanged,
  }) async {
    if (_peerConnections.containsKey(webSocketId)) return;
    try {
      if (!micPermissionGranted) {
        final granted = await _ensurePermissions();
        if (!granted) {
          lastError = 'Microphone denied';
          onError?.call(lastError!);
          return;
        }
      }
      final iceConfig = await _fetchIceConfig();
      final pc = await createPeerConnection(iceConfig);
      _peerConnections[webSocketId] = pc;
      MediaStream? localStream = _localStreams[webSocketId];
      if (localStream == null) {
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
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _log('✅ [WebRTC] CONNECTED to $webSocketId');
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
      final offer = await pc.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });
      await pc.setLocalDescription(offer);
      _markOfferSent();
      audioRealtime.emitOffer(
        caseId: caseId,
        offer: {'sdp': offer.sdp, 'type': offer.type},
        webSocketId: webSocketId,
      );
      onStateChanged?.call();
    } catch (e) {
      lastError = 'WebRTC start failed: $e';
      onError?.call(lastError!);
      await stopConnection(webSocketId: webSocketId);
    }
  }

  Future<void> handleAnswer({
    required String webSocketId,
    required dynamic sdpOrAnswer,
    VoidCallback? onStateChanged,
  }) async {
    final pc = _peerConnections[webSocketId];
    if (pc == null) return;
    String? sdp;
    String type = 'answer';
    if (sdpOrAnswer is String) {
      sdp = sdpOrAnswer;
    } else if (sdpOrAnswer is Map) {
      sdp = sdpOrAnswer['sdp']?.toString();
      type = sdpOrAnswer['type']?.toString() ?? 'answer';
    }
    if (sdp == null || sdp.isEmpty) return;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    _markAnswerReceived();
    _updateAggregateState(webSocketId, pc);
    onStateChanged?.call();
  }

  Future<void> handleRemoteIceCandidate({
    required String webSocketId,
    required Map<String, dynamic> candidate,
    VoidCallback? onStateChanged,
  }) async {
    final pc = _peerConnections[webSocketId];
    if (pc == null) return;
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
    await pc.addCandidate(iceCandidate);
    onStateChanged?.call();
  }

  void _removeConnection(String webSocketId) {
    final pc = _peerConnections.remove(webSocketId);
    pc?.close();
    final stream = _localStreams.remove(webSocketId);
    stream?.dispose();
    _recalculateAggregates();
  }

  void _recalculateAggregates() {
    if (_peerConnections.isEmpty) {
      _aggregateSignalingState = '-';
      _aggregateIceConnectionState = '-';
      _aggregateConnectionState = '-';
      return;
    }
    final firstPc = _peerConnections.values.first;
    _aggregateSignalingState = firstPc.signalingState?.toString() ?? '-';
    _aggregateIceConnectionState = firstPc.iceConnectionState?.toString() ?? '-';
    _aggregateConnectionState = firstPc.connectionState?.toString() ?? '-';
  }

  Future<void> stopConnection({required String webSocketId}) async {
    _removeConnection(webSocketId);
  }

  Future<void> stopAll() async {
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
  }

  bool isConnected(String webSocketId) {
    return _peerConnections.containsKey(webSocketId);
  }

  List<String> getConnectedUsers() {
    return _peerConnections.keys.toList();
  }

  Future<void> dispose() async {
    await stopAll();
  }

  static bool shouldAutoStartMedia(String caseId) => caseId.startsWith('CL');
}
*/
