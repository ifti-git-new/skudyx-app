import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:skudyx/core/config/app_config.dart';
import 'package:skudyx/core/storage/auth_token_storage.dart';

class AudioStreamEndedEvent {
  final String? caseId;
  AudioStreamEndedEvent({required this.caseId});
}

class WebRtcAnswerEvent {
  final String caseId;
  final dynamic sdpOrAnswer;
  final String? senderId;
  final String? requesterId; // ✅ ADDED: Web's socket ID

  WebRtcAnswerEvent({
    required this.caseId,
    required this.sdpOrAnswer,
    this.senderId,
    this.requesterId, // ✅ ADDED
  });
}

class WebRtcIceCandidateEvent {
  final String caseId;
  final Map<String, dynamic> candidate;
  final String? senderId;

  WebRtcIceCandidateEvent({
    required this.caseId,
    required this.candidate,
    this.senderId,
  });
}

class WebRtcRequestOfferEvent {
  final String caseId;
  final String webSocketId;

  WebRtcRequestOfferEvent({required this.caseId, required this.webSocketId});
}

class CaseAudioRealtimeService {
  final AppConfig config;
  final AuthTokenStorage tokenStorage;

  CaseAudioRealtimeService({required this.config, required this.tokenStorage});

  IO.Socket? _socket;
  String? _watchingCaseId;
  String? _currentSocketId;

  final _endedController = StreamController<AudioStreamEndedEvent>.broadcast();
  final _answerController = StreamController<WebRtcAnswerEvent>.broadcast();
  final _iceController = StreamController<WebRtcIceCandidateEvent>.broadcast();
  final _requestOfferController =
      StreamController<WebRtcRequestOfferEvent>.broadcast();

  Stream<AudioStreamEndedEvent> get endedStream => _endedController.stream;
  Stream<WebRtcAnswerEvent> get answerStream => _answerController.stream;
  Stream<WebRtcIceCandidateEvent> get iceCandidateStream =>
      _iceController.stream;
  Stream<WebRtcRequestOfferEvent> get requestOfferStream =>
      _requestOfferController.stream;

  bool get isConnected => _socket?.connected == true;
  String? get socketId => _currentSocketId;

  void _log(String message) {
    if (kDebugMode) print(message);
  }

  Future<void> connectIfNeeded() async {
    if (_socket != null) return;

    _log('\n🔌 [SOCKET] Connecting to: ${config.wsUrl}');

    final token = await tokenStorage.readAccessToken();
    final url = config.wsUrl;

    final socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
      'query': {'token': token},
      'extraHeaders': token == null ? {} : {'Authorization': 'Bearer $token'},
    });

    _socket = socket;

    socket.onConnect((_) {
      _currentSocketId = socket.id;
      _log('✅ [SOCKET] Connected! Socket ID: $_currentSocketId');

      if (_watchingCaseId != null) {
        socket.emit('join_case', _watchingCaseId);
        _log('📁 [SOCKET] Joined case: $_watchingCaseId');
      }
    });

    socket.onAny((event, data) {
      _log('📥 [SOCKET] Event: $event | Data: $data');
    });

    // ✅ Listen for request_offer from Web
    socket.on('request_offer', (data) {
      _log('\n📡 [WEB → MOBILE] request_offer');
      _log('📡 [WEB → MOBILE] Data: $data');

      if (data is Map) {
        final caseId = data['case_id']?.toString();
        final webSocketId = data['requester_id']?.toString();

        if (caseId != null && webSocketId != null) {
          _requestOfferController.add(
            WebRtcRequestOfferEvent(caseId: caseId, webSocketId: webSocketId),
          );
        }
      }
    });

    // ✅ Listen for webrtc_answer from Web - WITH requesterId
    socket.on('webrtc_answer', (data) {
      _log('\n📡 [WEB → MOBILE] webrtc_answer');
      _log('📡 [WEB → MOBILE] Full  $data');

      if (data is Map) {
        _log('📡 [WEB → MOBILE] All keys: ${data.keys.toList()}');
        _log('📡 [WEB → MOBILE] case_id: ${data['case_id']}');
        _log('📡 [WEB → MOBILE] sender_id: ${data['sender_id']}');
        _log('📡 [WEB → MOBILE] requester_id: ${data['requester_id']}');

        final caseId = data['case_id']?.toString();
        final sdp = data['sdp'];
        final senderId = data['sender_id']?.toString();
        final requesterId = data['requester_id']
            ?.toString(); // ✅ Extract requester_id

        if (caseId != null && sdp != null) {
          _log('📡 [WEB → MOBILE] ✅ Adding answer to stream');
          _answerController.add(
            WebRtcAnswerEvent(
              caseId: caseId,
              sdpOrAnswer: sdp,
              senderId: senderId,
              requesterId: requesterId, // ✅ Pass requester_id
            ),
          );
        } else {
          _log('❌ [WEB → MOBILE] ❌ Missing required fields');
          _log(
            '❌ [WEB → MOBILE] caseId: $caseId, sdp: ${sdp != null}, senderId: $senderId, requesterId: $requesterId',
          );
        }
      } else {
        _log('❌ [WEB → MOBILE] Data is not a Map: ${data.runtimeType}');
      }
    });

    // ✅ Listen for ICE candidates from Web
    socket.on('webrtc_ice_candidate', (data) {
      _log('\n📡 [WEB → MOBILE] webrtc_ice_candidate');
      _log('📡 [WEB → MOBILE] Data: $data');

      if (data is Map) {
        final caseId = data['case_id']?.toString();
        final candidate = data['candidate'];
        final senderId = data['sender_id']?.toString();

        if (caseId != null && candidate is Map) {
          _iceController.add(
            WebRtcIceCandidateEvent(
              caseId: caseId,
              candidate: Map<String, dynamic>.from(candidate),
              senderId: senderId,
            ),
          );
        }
      }
    });

    socket.on('audio_stream_ended', (data) {
      _log('\n📡 [SERVER] audio_stream_ended: $data');
      if (data is Map) {
        _endedController.add(
          AudioStreamEndedEvent(caseId: data['case_id']?.toString()),
        );
      } else if (data is String) {
        _endedController.add(AudioStreamEndedEvent(caseId: data));
      } else {
        _endedController.add(AudioStreamEndedEvent(caseId: _watchingCaseId));
      }
    });

    socket.onDisconnect((_) {
      _log('\n🔌 [SOCKET] Disconnected');
      _currentSocketId = null;
    });

    socket.connect();
  }

  Future<void> watchCase(String caseId) async {
    await connectIfNeeded();
    _watchingCaseId = caseId;
    _socket?.emit('join_case', caseId);
    _log('📤 [MOBILE] join_case: $caseId');
  }

  void emitOffer({
    required String caseId,
    required Map<String, dynamic> offer,
    required String webSocketId,
  }) {
    final mobileSocketId = _currentSocketId;

    _log('\n📤 [MOBILE → WEB] webrtc_offer');
    _log('📤 [MOBILE → WEB] case_id: $caseId');
    _log('📤 [MOBILE → WEB] requester_id (web): $webSocketId');
    _log('📤 [MOBILE → WEB] sender_id (mobile): $mobileSocketId');

    _socket?.emit('webrtc_offer', {
      'case_id': caseId,
      'offer': offer,
      'requester_id': webSocketId,
      'sender_id': mobileSocketId,
    });
  }

  void emitIceCandidate({
    required String caseId,
    required Map<String, dynamic> candidate,
    required String webSocketId,
  }) {
    _log('\n📤 [MOBILE → WEB] webrtc_ice_candidate');
    _log('📤 [MOBILE → WEB] case_id: $caseId');
    _log('📤 [MOBILE → WEB] requester_id (web): $webSocketId');

    _socket?.emit('webrtc_ice_candidate', {
      'case_id': caseId,
      'candidate': candidate,
      'requester_id': webSocketId,
      'sender_id': _currentSocketId,
    });
  }

  Future<void> unwatchCase() async {
    _log('📤 [MOBILE] unwatchCase: $_watchingCaseId');
    _watchingCaseId = null;
  }

  Future<void> dispose() async {
    await unwatchCase();
    _socket?.dispose();
    _socket = null;
    _currentSocketId = null;
    await _endedController.close();
    await _answerController.close();
    await _iceController.close();
    await _requestOfferController.close();
  }
}
