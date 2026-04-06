// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:skudyx/core/config/app_config.dart';
// import 'package:skudyx/core/storage/auth_token_storage.dart';

// class EmergencyAudioSignalEvent {
//   final String? caseId;
//   final bool shouldStartAudio;

//   EmergencyAudioSignalEvent({
//     required this.caseId,
//     required this.shouldStartAudio,
//   });
// }

// class AudioStreamEndedEvent {
//   final String? caseId;

//   AudioStreamEndedEvent({required this.caseId});
// }

// class WebRtcAnswerEvent {
//   final String caseId;
//   final String sdp;
//   final String type;

//   WebRtcAnswerEvent({
//     required this.caseId,
//     required this.sdp,
//     required this.type,
//   });
// }

// class WebRtcIceCandidateEvent {
//   final String caseId;
//   final Map<String, dynamic> candidate;

//   WebRtcIceCandidateEvent({required this.caseId, required this.candidate});
// }

// class CaseAudioRealtimeService {
//   final AppConfig config;
//   final AuthTokenStorage tokenStorage;

//   CaseAudioRealtimeService({required this.config, required this.tokenStorage});

//   IO.Socket? _socket;
//   String? _watchingCaseId;
//   String? _joinedUserId;

//   final _emergencyController =
//       StreamController<EmergencyAudioSignalEvent>.broadcast();
//   final _endedController = StreamController<AudioStreamEndedEvent>.broadcast();
//   final _answerController = StreamController<WebRtcAnswerEvent>.broadcast();
//   final _iceController = StreamController<WebRtcIceCandidateEvent>.broadcast();

//   Stream<EmergencyAudioSignalEvent> get emergencyStream =>
//       _emergencyController.stream;
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

//       if (_joinedUserId != null) {
//         socket.emit('join_user_room', _joinedUserId);
//         if (kDebugMode) {
//           print('[AudioSocket] join_user_room => $_joinedUserId');
//         }
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

//     socket.on('emergency_response', (data) {
//       if (kDebugMode) {
//         print('[AudioSocket] emergency_response => $data');
//       }

//       if (data is Map) {
//         _emergencyController.add(
//           EmergencyAudioSignalEvent(
//             caseId: data['case_id']?.toString(),
//             shouldStartAudio: data['should_start_audio'] == true,
//           ),
//         );
//       }
//     });

//     socket.on('webrtc_answer', (data) {
//       if (kDebugMode) {
//         print('[AudioSocket] webrtc_answer => $data');
//       }

//       if (data is Map) {
//         final caseId = data['case_id']?.toString();
//         final sdp = data['sdp']?.toString();

//         if (caseId != null && sdp != null) {
//           _answerController.add(
//             WebRtcAnswerEvent(caseId: caseId, sdp: sdp, type: 'answer'),
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
//           AudioStreamEndedEvent(caseId: data['case_id']?.toString()),
//         );
//       } else if (data is String) {
//         _endedController.add(AudioStreamEndedEvent(caseId: data));
//       } else {
//         _endedController.add(AudioStreamEndedEvent(caseId: _watchingCaseId));
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

//   Future<void> joinUserRoom(String userId) async {
//     await connectIfNeeded();
//     _joinedUserId = userId;
//     _socket?.emit('join_user_room', userId);

//     if (kDebugMode) {
//       print('[AudioSocket] joinUserRoom => $userId');
//     }
//   }

//   Future<void> watchCase(String caseId) async {
//     await connectIfNeeded();
//     _watchingCaseId = caseId;
//     _socket?.emit('join_case', caseId);

//     if (kDebugMode) {
//       print('[AudioSocket] watchCase => $caseId');
//     }
//   }

//   void emitOffer({required String caseId, required String sdp}) {
//     _socket?.emit('webrtc_offer', {
//       'case_id': caseId,
//       'sdp': sdp,
//       'type': 'offer',
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
//     await _emergencyController.close();
//     await _endedController.close();
//     await _answerController.close();
//     await _iceController.close();
//   }
// }

// lib/core/realtime/case_audio_realtime_service.dart
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

  WebRtcAnswerEvent({required this.caseId, required this.sdpOrAnswer});
}

class WebRtcIceCandidateEvent {
  final String caseId;
  final Map<String, dynamic> candidate;

  WebRtcIceCandidateEvent({required this.caseId, required this.candidate});
}

class CaseAudioRealtimeService {
  final AppConfig config;
  final AuthTokenStorage tokenStorage;

  CaseAudioRealtimeService({required this.config, required this.tokenStorage});

  IO.Socket? _socket;
  String? _watchingCaseId;

  final _endedController = StreamController<AudioStreamEndedEvent>.broadcast();
  final _answerController = StreamController<WebRtcAnswerEvent>.broadcast();
  final _iceController = StreamController<WebRtcIceCandidateEvent>.broadcast();

  Stream<AudioStreamEndedEvent> get endedStream => _endedController.stream;
  Stream<WebRtcAnswerEvent> get answerStream => _answerController.stream;
  Stream<WebRtcIceCandidateEvent> get iceCandidateStream =>
      _iceController.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connectIfNeeded() async {
    if (_socket != null) return;

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
      if (kDebugMode) {
        print('[AudioSocket] connected');
      }

      if (_watchingCaseId != null) {
        socket.emit('join_case', _watchingCaseId);
        if (kDebugMode) {
          print('[AudioSocket] join_case => $_watchingCaseId');
        }
      }
    });

    socket.onAny((event, data) {
      if (kDebugMode) {
        print('[AudioSocket][ANY] event=$event data=$data');
      }
    });

    socket.on('webrtc_answer', (data) {
      if (kDebugMode) {
        print('[AudioSocket] webrtc_answer => $data');
      }

      if (data is Map) {
        final caseId = data['case_id']?.toString();
        final sdp = data['sdp'];

        if (caseId != null && sdp != null) {
          _answerController.add(
            WebRtcAnswerEvent(caseId: caseId, sdpOrAnswer: sdp),
          );
        }
      }
    });

    socket.on('webrtc_ice_candidate', (data) {
      if (kDebugMode) {
        print('[AudioSocket] webrtc_ice_candidate => $data');
      }

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
      if (kDebugMode) {
        print('[AudioSocket] audio_stream_ended => $data');
      }

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

    socket.onDisconnect((data) {
      if (kDebugMode) {
        print('[AudioSocket] disconnected => $data');
      }
    });

    socket.onConnectError((data) {
      if (kDebugMode) {
        print('[AudioSocket] connect_error => $data');
      }
    });

    socket.onError((data) {
      if (kDebugMode) {
        print('[AudioSocket] error => $data');
      }
    });

    socket.connect();
  }

  Future<void> watchCase(String caseId) async {
    await connectIfNeeded();
    _watchingCaseId = caseId;
    _socket?.emit('join_case', caseId);

    if (kDebugMode) {
      print('[AudioSocket] watchCase => $caseId');
    }
  }

  void emitOffer({
    required String caseId,
    required Map<String, dynamic> offer,
  }) {
    _socket?.emit('webrtc_offer', {'case_id': caseId, 'offer': offer});

    if (kDebugMode) {
      print('[AudioSocket] emit webrtc_offer => $caseId');
    }
  }

  void emitIceCandidate({
    required String caseId,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit('webrtc_ice_candidate', {
      'case_id': caseId,
      'candidate': candidate,
    });

    if (kDebugMode) {
      print('[AudioSocket] emit webrtc_ice_candidate => $caseId');
    }
  }

  Future<void> unwatchCase() async {
    if (kDebugMode) {
      print('[AudioSocket] unwatchCase => $_watchingCaseId');
    }
    _watchingCaseId = null;
  }

  Future<void> dispose() async {
    await unwatchCase();
    _socket?.dispose();
    _socket = null;
    await _endedController.close();
    await _answerController.close();
    await _iceController.close();
  }
}
