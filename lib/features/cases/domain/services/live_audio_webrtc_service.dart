// import 'package:flutter/foundation.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';

// class LiveAudioWebRtcService {
//   final CaseAudioRealtimeService audioRealtime;

//   LiveAudioWebRtcService({required this.audioRealtime});

//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;

//   bool _starting = false;
//   bool _started = false;
//   String? _caseId;

//   bool micPermissionGranted = false;
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
//   bool get hasLocalAudioTrack =>
//       _localStream?.getAudioTracks().isNotEmpty == true;

//   final Map<String, dynamic> _rtcConfig = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {'urls': 'stun:stun1.l.google.com:19302'},
//     ],
//   };

//   Future<bool> _ensureMicPermission() async {
//     final status = await Permission.microphone.request();
//     micPermissionGranted = status.isGranted;

//     if (kDebugMode) {
//       print('[WebRTC] mic permission => $status');
//     }

//     return status.isGranted;
//   }

//   Future<void> start({
//     required String caseId,
//     void Function(String error)? onError,
//     VoidCallback? onStateChanged,
//   }) async {
//     if (_starting || _started) return;

//     _starting = true;
//     _caseId = caseId;

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

//       final granted = await _ensureMicPermission();
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
//         onStateChanged?.call();
//       };

//       _peerConnection!.onIceConnectionState = (state) {
//         iceConnectionState = state.toString();
//         if (kDebugMode) {
//           print('[WebRTC] ice connection state => $state');
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
//         print('[WebRTC] local stream acquired');
//       }

//       for (final track in _localStream!.getAudioTracks()) {
//         await _peerConnection!.addTrack(track, _localStream!);
//       }

//       final offer = await _peerConnection!.createOffer({
//         'offerToReceiveAudio': false,
//         'offerToReceiveVideo': false,
//       });

//       await _peerConnection!.setLocalDescription(offer);

//       offerSent = true;
//       onStateChanged?.call();

//       if (kDebugMode) {
//         print('[WebRTC] sending offer');
//       }

//       audioRealtime.emitOffer(caseId: caseId, sdp: offer.sdp ?? '');

//       _started = true;
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

//   Future<void> handleAnswer({
//     required String sdp,
//     required String type,
//     VoidCallback? onStateChanged,
//   }) async {
//     final pc = _peerConnection;
//     if (pc == null) return;

//     if (kDebugMode) {
//       print('[WebRTC] received answer');
//     }

//     await pc.setRemoteDescription(RTCSessionDescription(sdp, type));

//     answerReceived = true;
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

//     _started = false;
//     _starting = false;
//     _caseId = null;

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
