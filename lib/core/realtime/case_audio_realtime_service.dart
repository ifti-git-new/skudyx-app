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
  final String? senderId; // Mobile's socket ID (for reference)

  WebRtcAnswerEvent({
    required this.caseId,
    required this.sdpOrAnswer,
    this.senderId,
  });
}

class WebRtcIceCandidateEvent {
  final String caseId;
  final Map<String, dynamic> candidate;

  WebRtcIceCandidateEvent({required this.caseId, required this.candidate});
}

class WebRtcRequestOfferEvent {
  final String caseId;
  final String webSocketId; // ✅ Web's socket ID (from request_offer)

  WebRtcRequestOfferEvent({required this.caseId, required this.webSocketId});
}

class CaseAudioRealtimeService {
  final AppConfig config;
  final AuthTokenStorage tokenStorage;

  CaseAudioRealtimeService({required this.config, required this.tokenStorage});

  IO.Socket? _socket;
  String? _watchingCaseId;
  String? _currentSocketId; // ✅ Mobile's socket ID

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

    // ✅ LOG ALL EVENTS
    socket.onAny((event, data) {
      _log('📥 [SOCKET] Event: $event | Data: $data');
    });

    // ✅ Listen for request_offer from Web (matches web's emit pattern)
    socket.on('request_offer', (data) {
      _log('\n📡 [WEB → MOBILE] request_offer');
      _log('📡 [WEB → MOBILE] Data: $data');

      if (data is Map) {
        final caseId = data['case_id']?.toString();
        final webSocketId = data['requester_id']
            ?.toString(); // ✅ Web's socket ID

        if (caseId != null && webSocketId != null) {
          _log('📡 [WEB → MOBILE] Web Socket ID: $webSocketId');
          _requestOfferController.add(
            WebRtcRequestOfferEvent(
              caseId: caseId,
              webSocketId: webSocketId, // ✅ Pass web's socket ID
            ),
          );
        }
      }
    });

    // ✅ Listen for webrtc_answer from Web
    socket.on('webrtc_answer', (data) {
      _log('\n📡 [WEB → MOBILE] webrtc_answer');
      _log('📡 [WEB → MOBILE] Data: $data');

      if (data is Map) {
        final caseId = data['case_id']?.toString();
        final sdp = data['sdp'];
        final senderId = data['sender_id']
            ?.toString(); // ✅ Mobile's ID (preserved)

        if (caseId != null && sdp != null) {
          _answerController.add(
            WebRtcAnswerEvent(
              caseId: caseId,
              sdpOrAnswer: sdp,
              senderId: senderId,
            ),
          );
        }
      }
    });

    // ✅ Listen for ICE candidates from Web
    socket.on('webrtc_ice_candidate', (data) {
      _log('\n📡 [WEB → MOBILE] webrtc_ice_candidate');
      _log('📡 [WEB → MOBILE] Data: $data');

      if (data is Map) {
        final caseId = data['case_id']?.toString();
        final candidate = data['candidate'];

        if (caseId != null && candidate is Map) {
          _iceController.add(
            WebRtcIceCandidateEvent(
              caseId: caseId,
              candidate: Map<String, dynamic>.from(candidate),
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

  /// ✅ Send offer to Web - MATCHES WEB'S EXPECTED FORMAT
  void emitOffer({
    required String caseId,
    required Map<String, dynamic> offer,
    required String webSocketId, // ✅ Web's socket ID (for routing)
  }) {
    final mobileSocketId = _currentSocketId;

    _log('\n📤 [MOBILE → WEB] webrtc_offer');
    _log('📤 [MOBILE → WEB] case_id: $caseId');
    _log('📤 [MOBILE → WEB] requester_id (web): $webSocketId');
    _log('📤 [MOBILE → WEB] sender_id (mobile): $mobileSocketId');

    _socket?.emit('webrtc_offer', {
      'case_id': caseId,
      'offer': offer,
      'requester_id': webSocketId, // ✅ Route to web
      'sender_id': mobileSocketId, // ✅ Mobile's ID for reference
    });
  }

  /// ✅ Send ICE to Web - MATCHES WEB'S EXPECTED FORMAT
  void emitIceCandidate({
    required String caseId,
    required Map<String, dynamic> candidate,
    required String webSocketId, // ✅ Web's socket ID (for routing)
  }) {
    _log('\n📤 [MOBILE → WEB] webrtc_ice_candidate');
    _log('📤 [MOBILE → WEB] case_id: $caseId');
    _log('📤 [MOBILE → WEB] requester_id (web): $webSocketId');

    _socket?.emit('webrtc_ice_candidate', {
      'case_id': caseId,
      'candidate': candidate,
      'requester_id': webSocketId, // ✅ Route to web
      'sender_id': _currentSocketId, // ✅ Mobile's ID
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

// for 5sec data send//
// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:skudyx/core/config/app_config.dart';
// import 'package:skudyx/core/storage/auth_token_storage.dart';

// class AudioStreamEndedEvent {
//   final String? caseId;

//   AudioStreamEndedEvent({required this.caseId});
// }

// class WebRtcAnswerEvent {
//   final String caseId;
//   final dynamic sdpOrAnswer;

//   WebRtcAnswerEvent({
//     required this.caseId,
//     required this.sdpOrAnswer,
//   });
// }

// class WebRtcIceCandidateEvent {
//   final String caseId;
//   final Map<String, dynamic> candidate;

//   WebRtcIceCandidateEvent({
//     required this.caseId,
//     required this.candidate,
//   });
// }

// class CaseAudioRealtimeService {
//   final AppConfig config;
//   final AuthTokenStorage tokenStorage;

//   CaseAudioRealtimeService({
//     required this.config,
//     required this.tokenStorage,
//   });

//   IO.Socket? _socket;
//   String? _watchingCaseId;

//   final _endedController = StreamController<AudioStreamEndedEvent>.broadcast();
//   final _answerController = StreamController<WebRtcAnswerEvent>.broadcast();
//   final _iceController = StreamController<WebRtcIceCandidateEvent>.broadcast();

//   Stream<AudioStreamEndedEvent> get endedStream => _endedController.stream;
//   Stream<WebRtcAnswerEvent> get answerStream => _answerController.stream;
//   Stream<WebRtcIceCandidateEvent> get iceCandidateStream =>
//       _iceController.stream;

//   bool get isConnected => _socket?.connected == true;

//   Future<void> connectIfNeeded() async {
//     if (_socket != null) return;

//     final token = await tokenStorage.readAccessToken();
//     final url = config.wsUrl;

//     final socket = IO.io(url, <String, dynamic>{
//       'transports': ['websocket', 'polling'],
//       'autoConnect': false,
//       'forceNew': true,
//       'auth': {'token': token},
//       'query': {'token': token},
//       'extraHeaders': token == null ? {} : {'Authorization': 'Bearer $token'},
//     });

//     _socket = socket;

//     socket.onConnect((_) {
//       if (kDebugMode) {
//         print('[AudioSocket] connected');
//       }

//       if (_watchingCaseId != null) {
//         socket.emit('join_case', _watchingCaseId);
//         if (kDebugMode) {
//           print('[AudioSocket] join_case => $_watchingCaseId');
//         }
//       }
//     });

//     socket.onAny((event, data) {
//       if (kDebugMode) {
//         print('[AudioSocket][ANY] event=$event data=$data');
//       }
//     });

//     socket.on('webrtc_answer', (data) {
//       if (kDebugMode) {
//         print('[AudioSocket] webrtc_answer => $data');
//       }

//       if (data is Map) {
//         final caseId = data['case_id']?.toString();
//         final sdp = data['sdp'];

//         if (caseId != null && sdp != null) {
//           _answerController.add(
//             WebRtcAnswerEvent(
//               caseId: caseId,
//               sdpOrAnswer: data,
//             ),
//           );
//         }
//       }
//     });

//     socket.on('webrtc_ice_candidate', (data) {
//       if (kDebugMode) {
//         print('[AudioSocket] webrtc_ice_candidate => $data');
//       }

//       if (data is Map) {
//         final caseId = data['case_id']?.toString();
//         final candidate = data['candidate'];

//         if (caseId != null && candidate is Map) {
//           _iceController.add(
//             WebRtcIceCandidateEvent(
//               caseId: caseId,
//               candidate: Map<String, dynamic>.from(candidate),
//             ),
//           );
//         }
//       }
//     });

//     socket.on('audio_stream_ended', (data) {
//       if (kDebugMode) {
//         print('[AudioSocket] audio_stream_ended => $data');
//       }

//       if (data is Map) {
//         _endedController.add(
//           AudioStreamEndedEvent(
//             caseId: data['case_id']?.toString(),
//           ),
//         );
//       } else if (data is String) {
//         _endedController.add(AudioStreamEndedEvent(caseId: data));
//       } else {
//         _endedController.add(
//           AudioStreamEndedEvent(caseId: _watchingCaseId),
//         );
//       }
//     });

//     socket.onDisconnect((data) {
//       if (kDebugMode) {
//         print('[AudioSocket] disconnected => $data');
//       }
//     });

//     socket.onConnectError((data) {
//       if (kDebugMode) {
//         print('[AudioSocket] connect_error => $data');
//       }
//     });

//     socket.onError((data) {
//       if (kDebugMode) {
//         print('[AudioSocket] error => $data');
//       }
//     });

//     socket.connect();
//   }

//   Future<void> watchCase(String caseId) async {
//     await connectIfNeeded();
//     _watchingCaseId = caseId;
//     _socket?.emit('join_case', caseId);

//     if (kDebugMode) {
//       print('[AudioSocket] watchCase => $caseId');
//     }
//   }

//   void rejoinCase(String caseId) {
//     _watchingCaseId = caseId;
//     _socket?.emit('join_case', caseId);

//     if (kDebugMode) {
//       print('[AudioSocket] rejoinCase => $caseId');
//     }
//   }

//   void emitOffer({
//     required String caseId,
//     required Map<String, dynamic> offer,
//   }) {
//     _socket?.emit('webrtc_offer', {
//       'case_id': caseId,
//       'offer': offer,
//     });

//     if (kDebugMode) {
//       print('[AudioSocket] emit webrtc_offer => $caseId');
//     }
//   }

//   void emitIceCandidate({
//     required String caseId,
//     required Map<String, dynamic> candidate,
//   }) {
//     _socket?.emit('webrtc_ice_candidate', {
//       'case_id': caseId,
//       'candidate': candidate,
//     });

//     if (kDebugMode) {
//       print('[AudioSocket] emit webrtc_ice_candidate => $caseId');
//     }
//   }

//   Future<void> unwatchCase() async {
//     if (kDebugMode) {
//       print('[AudioSocket] unwatchCase => $_watchingCaseId');
//     }
//     _watchingCaseId = null;
//   }

//   Future<void> dispose() async {
//     await unwatchCase();
//     _socket?.dispose();
//     _socket = null;
//     await _endedController.close();
//     await _answerController.close();
//     await _iceController.close();
//   }
// }
