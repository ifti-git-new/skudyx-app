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

  bool get isStarted => _started;
  MediaStream? get localStream => _localStream;
  bool get hasLocalAudioTrack =>
      _localStream?.getAudioTracks().isNotEmpty == true;

  // Video currently disabled
  bool get hasLocalVideoTrack => false;
  // bool get hasLocalVideoTrack =>
  //     _localStream?.getVideoTracks().isNotEmpty == true;

  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  Future<bool> _ensurePermissions() async {
    final mic = await Permission.microphone.request();

    micPermissionGranted = mic.isGranted;

    // Video currently disabled
    cameraPermissionGranted = false;

    // final cam = await Permission.camera.request();
    // cameraPermissionGranted = cam.isGranted;

    if (kDebugMode) {
      print('[WebRTC] mic permission => $mic');
      // print('[WebRTC] camera permission => $cam');
    }

    return mic.isGranted;

    // For audio + video later:
    // return mic.isGranted && cam.isGranted;
  }

  Future<void> start({
    required String caseId,
    void Function(String error)? onError,
    VoidCallback? onStateChanged,
  }) async {
    if (_starting || _started) return;

    _starting = true;
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
      if (kDebugMode) {
        print('[WebRTC] start => $caseId');
      }

      final granted = await _ensurePermissions();
      onStateChanged?.call();

      if (!granted) {
        lastError = 'Microphone permission denied.';
        onError?.call(lastError!);
        _starting = false;
        onStateChanged?.call();
        return;
      }

      _peerConnection = await createPeerConnection(_rtcConfig);

      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;

        sentIceCandidates++;

        if (kDebugMode) {
          print('[WebRTC] local ICE => ${candidate.candidate}');
        }

        audioRealtime.emitIceCandidate(
          caseId: caseId,
          candidate: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );

        onStateChanged?.call();
      };

      _peerConnection!.onConnectionState = (state) {
        connectionState = state.toString();
        if (kDebugMode) {
          print('[WebRTC] connection state => $state');
        }
        onStateChanged?.call();
      };

      _peerConnection!.onIceConnectionState = (state) {
        iceConnectionState = state.toString();
        if (kDebugMode) {
          print('[WebRTC] ice connection state => $state');
        }
        onStateChanged?.call();
      };

      _peerConnection!.onSignalingState = (state) {
        signalingState = state.toString();
        if (kDebugMode) {
          print('[WebRTC] signaling state => $state');
        }
        onStateChanged?.call();
      };

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,

        // For audio + video later:
        // 'video': {
        //   'facingMode': 'user',
        // },
      });

      localStreamAcquired = true;
      onStateChanged?.call();

      if (kDebugMode) {
        print('[WebRTC] local audio stream acquired');
      }

      // Audio track only for now
      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      // For audio + video later:
      // for (final track in _localStream!.getTracks()) {
      //   await _peerConnection!.addTrack(track, _localStream!);
      // }

      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });

      await _peerConnection!.setLocalDescription(offer);

      offerSent = true;
      onStateChanged?.call();

      if (kDebugMode) {
        print('[WebRTC] sending offer');
      }

      audioRealtime.emitOffer(
        caseId: caseId,
        offer: {'sdp': offer.sdp, 'type': offer.type},
      );

      _started = true;
      onStateChanged?.call();
    } catch (e) {
      lastError = 'WebRTC start failed: $e';
      if (kDebugMode) {
        print('[WebRTC] $lastError');
      }
      onError?.call(lastError!);
      await stop(onStateChanged: onStateChanged);
    } finally {
      _starting = false;
      onStateChanged?.call();
    }
  }

  Future<void> handleAnswer(
    dynamic sdpOrAnswer, {
    VoidCallback? onStateChanged,
  }) async {
    final pc = _peerConnection;
    if (pc == null) return;

    String? sdp;
    String type = 'answer';

    if (sdpOrAnswer is String) {
      sdp = sdpOrAnswer;
    } else if (sdpOrAnswer is Map) {
      sdp = sdpOrAnswer['sdp']?.toString();
      type = sdpOrAnswer['type']?.toString() ?? 'answer';
    }

    if (sdp == null || sdp.isEmpty) {
      lastError = 'Invalid WebRTC answer payload.';
      onStateChanged?.call();
      return;
    }

    if (kDebugMode) {
      print('[WebRTC] received answer');
    }

    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));

    answerReceived = true;
    onStateChanged?.call();
  }

  Future<void> handleRemoteIceCandidate(
    Map<String, dynamic> data, {
    VoidCallback? onStateChanged,
  }) async {
    final pc = _peerConnection;
    if (pc == null) return;

    final candidate = RTCIceCandidate(
      data['candidate']?.toString(),
      data['sdpMid']?.toString(),
      data['sdpMLineIndex'] is int
          ? data['sdpMLineIndex'] as int
          : int.tryParse('${data['sdpMLineIndex']}'),
    );

    receivedIceCandidates++;

    if (kDebugMode) {
      print('[WebRTC] received remote ICE => ${candidate.candidate}');
    }

    await pc.addCandidate(candidate);
    onStateChanged?.call();
  }

  Future<void> stop({VoidCallback? onStateChanged}) async {
    if (kDebugMode) {
      print('[WebRTC] stop');
    }

    _started = false;
    _starting = false;

    try {
      await _peerConnection?.close();
    } catch (_) {}

    try {
      final stream = _localStream;
      if (stream != null) {
        for (final track in stream.getTracks()) {
          track.stop();
        }
        await stream.dispose();
      }
    } catch (_) {}

    _peerConnection = null;
    _localStream = null;
    localStreamAcquired = false;
    onStateChanged?.call();
  }

  Future<void> dispose() async {
    await stop();
  }
}


// for 5sec data send//
// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';

// class LiveMediaWebRtcService {
//   final CaseAudioRealtimeService audioRealtime;

//   LiveMediaWebRtcService({required this.audioRealtime});

//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   Timer? _retryTimer;

//   bool _starting = false;
//   bool _started = false;
//   String? _caseId;
//   Map<String, dynamic>? _lastOffer;

//   bool micPermissionGranted = false;
//   bool cameraPermissionGranted = false;
//   bool localStreamAcquired = false;
//   bool offerSent = false;
//   bool answerReceived = false;
//   int sentIceCandidates = 0;
//   int receivedIceCandidates = 0;
//   String? lastError;
//   String signalingState = '-';
//   String iceConnectionState = '-';
//   String connectionState = '-';

//   bool get isStarted => _started;
//   MediaStream? get localStream => _localStream;
//   bool get hasLocalAudioTrack =>
//       _localStream?.getAudioTracks().isNotEmpty == true;
//   bool get hasLocalVideoTrack => false;

//   final Map<String, dynamic> _rtcConfig = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {'urls': 'stun:stun1.l.google.com:19302'},
//     ],
//   };

//   bool get _shouldRetry {
//     if (!_started) return false;
//     if (_caseId == null) return false;

//     final isConnected = connectionState.contains('Connected') ||
//         iceConnectionState.contains('Connected');

//     return !answerReceived && !isConnected;
//   }

//   void _startRetryLoop(VoidCallback? onStateChanged) {
//     _retryTimer?.cancel();

//     _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       final caseId = _caseId;
//       if (caseId == null) return;

//       if (!_shouldRetry) {
//         if (kDebugMode) {
//           print('[WebRTC] retry loop stopped');
//         }
//         _retryTimer?.cancel();
//         return;
//       }

//       if (kDebugMode) {
//         print('[WebRTC] retry => join_case + resend offer');
//       }

//       audioRealtime.rejoinCase(caseId);

//       if (_lastOffer != null) {
//         audioRealtime.emitOffer(
//           caseId: caseId,
//           offer: _lastOffer!,
//         );
//       }

//       onStateChanged?.call();
//     });
//   }

//   Future<bool> _ensurePermissions() async {
//     final mic = await Permission.microphone.request();

//     micPermissionGranted = mic.isGranted;
//     cameraPermissionGranted = false;

//     if (kDebugMode) {
//       print('[WebRTC] mic permission => $mic');
//     }

//     return mic.isGranted;
//   }

//   Future<void> start({
//     required String caseId,
//     void Function(String error)? onError,
//     VoidCallback? onStateChanged,
//   }) async {
//     if (_starting || _started) return;

//     _starting = true;
//     _caseId = caseId;
//     _lastOffer = null;

//     offerSent = false;
//     answerReceived = false;
//     sentIceCandidates = 0;
//     receivedIceCandidates = 0;
//     localStreamAcquired = false;
//     lastError = null;
//     signalingState = '-';
//     iceConnectionState = '-';
//     connectionState = '-';
//     onStateChanged?.call();

//     try {
//       if (kDebugMode) {
//         print('[WebRTC] start => $caseId');
//       }

//       final granted = await _ensurePermissions();
//       onStateChanged?.call();

//       if (!granted) {
//         lastError = 'Microphone permission denied.';
//         onError?.call(lastError!);
//         _starting = false;
//         onStateChanged?.call();
//         return;
//       }

//       _peerConnection = await createPeerConnection(_rtcConfig);

//       _peerConnection!.onIceCandidate = (candidate) {
//         if (candidate.candidate == null || candidate.candidate!.isEmpty) return;

//         sentIceCandidates++;

//         if (kDebugMode) {
//           print('[WebRTC] local ICE => ${candidate.candidate}');
//         }

//         audioRealtime.emitIceCandidate(
//           caseId: caseId,
//           candidate: {
//             'candidate': candidate.candidate,
//             'sdpMid': candidate.sdpMid,
//             'sdpMLineIndex': candidate.sdpMLineIndex,
//           },
//         );

//         onStateChanged?.call();
//       };

//       _peerConnection!.onConnectionState = (state) {
//         connectionState = state.toString();

//         if (kDebugMode) {
//           print('[WebRTC] connection state => $state');
//         }

//         if (!_shouldRetry) {
//           _retryTimer?.cancel();
//         }

//         onStateChanged?.call();
//       };

//       _peerConnection!.onIceConnectionState = (state) {
//         iceConnectionState = state.toString();

//         if (kDebugMode) {
//           print('[WebRTC] ice connection state => $state');
//         }

//         if (!_shouldRetry) {
//           _retryTimer?.cancel();
//         }

//         onStateChanged?.call();
//       };

//       _peerConnection!.onSignalingState = (state) {
//         signalingState = state.toString();

//         if (kDebugMode) {
//           print('[WebRTC] signaling state => $state');
//         }

//         onStateChanged?.call();
//       };

//       _localStream = await navigator.mediaDevices.getUserMedia({
//         'audio': true,
//         'video': false,
//       });

//       localStreamAcquired = true;
//       onStateChanged?.call();

//       if (kDebugMode) {
//         print('[WebRTC] local audio stream acquired');
//       }

//       for (final track in _localStream!.getAudioTracks()) {
//         await _peerConnection!.addTrack(track, _localStream!);
//       }

//       final offer = await _peerConnection!.createOffer({
//         'offerToReceiveAudio': false,
//         'offerToReceiveVideo': false,
//       });

//       await _peerConnection!.setLocalDescription(offer);

//       _lastOffer = {
//         'sdp': offer.sdp,
//         'type': offer.type,
//       };

//       offerSent = true;
//       onStateChanged?.call();

//       if (kDebugMode) {
//         print('[WebRTC] sending initial offer');
//       }

//       audioRealtime.emitOffer(
//         caseId: caseId,
//         offer: _lastOffer!,
//       );

//       _started = true;
//       _startRetryLoop(onStateChanged);
//       onStateChanged?.call();
//     } catch (e) {
//       lastError = 'WebRTC start failed: $e';
//       if (kDebugMode) {
//         print('[WebRTC] $lastError');
//       }
//       onError?.call(lastError!);
//       await stop(onStateChanged: onStateChanged);
//     } finally {
//       _starting = false;
//       onStateChanged?.call();
//     }
//   }

//   Future<void> handleAnswer(
//     dynamic sdpOrAnswer, {
//     VoidCallback? onStateChanged,
//   }) async {
//     final pc = _peerConnection;
//     if (pc == null) return;

//     String? sdp;
//     String type = 'answer';

//     if (sdpOrAnswer is String) {
//       sdp = sdpOrAnswer;
//     } else if (sdpOrAnswer is Map) {
//       sdp = sdpOrAnswer['sdp']?.toString();
//       type = sdpOrAnswer['type']?.toString() ?? 'answer';
//     }

//     if (sdp == null || sdp.isEmpty) {
//       lastError = 'Invalid WebRTC answer payload.';
//       onStateChanged?.call();
//       return;
//     }

//     if (kDebugMode) {
//       print('[WebRTC] received answer');
//     }

//     await pc.setRemoteDescription(
//       RTCSessionDescription(sdp, type),
//     );

//     answerReceived = true;
//     _retryTimer?.cancel();
//     onStateChanged?.call();
//   }

//   Future<void> handleRemoteIceCandidate(
//     Map<String, dynamic> data, {
//     VoidCallback? onStateChanged,
//   }) async {
//     final pc = _peerConnection;
//     if (pc == null) return;

//     final candidate = RTCIceCandidate(
//       data['candidate']?.toString(),
//       data['sdpMid']?.toString(),
//       data['sdpMLineIndex'] is int
//           ? data['sdpMLineIndex'] as int
//           : int.tryParse('${data['sdpMLineIndex']}'),
//     );

//     receivedIceCandidates++;

//     if (kDebugMode) {
//       print('[WebRTC] received remote ICE => ${candidate.candidate}');
//     }

//     await pc.addCandidate(candidate);
//     onStateChanged?.call();
//   }

//   Future<void> stop({VoidCallback? onStateChanged}) async {
//     if (kDebugMode) {
//       print('[WebRTC] stop');
//     }

//     _retryTimer?.cancel();
//     _retryTimer = null;

//     _started = false;
//     _starting = false;
//     _caseId = null;
//     _lastOffer = null;

//     try {
//       await _peerConnection?.close();
//     } catch (_) {}

//     try {
//       final stream = _localStream;
//       if (stream != null) {
//         for (final track in stream.getTracks()) {
//           track.stop();
//         }
//         await stream.dispose();
//       }
//     } catch (_) {}

//     _peerConnection = null;
//     _localStream = null;
//     localStreamAcquired = false;
//     onStateChanged?.call();
//   }

//   Future<void> dispose() async {
//     await stop();
//   }
// }