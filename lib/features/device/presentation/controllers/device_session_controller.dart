// lib/features/device/presentation/controllers/device_session_controller.dart
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
    _rtSub = realtime.stream.listen(_onRealtimeUpdate);
    _audioEndedSub = audioRealtime.endedStream.listen(_onAudioEnded);
    _answerSub = audioRealtime.answerStream.listen(_onWebRtcAnswer);
    _iceSub = audioRealtime.iceCandidateStream.listen(_onWebRtcIce);
  }

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

  StreamSubscription<CaseUpdateEvent>? _rtSub;
  StreamSubscription<AudioStreamEndedEvent>? _audioEndedSub;
  StreamSubscription<WebRtcAnswerEvent>? _answerSub;
  StreamSubscription<WebRtcIceCandidateEvent>? _iceSub;

  static const _finalStatuses = {'Resolved', 'Unresolved', 'False'};

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

  Future<bool> startCase({
    required bool isTest,
    required String caseName,
  }) async {
    if (!isConnected) {
      _setError('No device connected.');
      return false;
    }

    if (starting || tracking) return false;

    clearError();
    lastAudioError = null;
    audioActive = false;

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

      final data = await caseApi.triggerCase(
        latitude: firstPos.latitude,
        longitude: firstPos.longitude,
        isTest: isTest,
      );

      final createdCaseId = (data['case_id'] ?? '').toString();
      if (createdCaseId.isEmpty) {
        throw Exception('Missing case_id');
      }

      if (kDebugMode) {
        print('[DeviceSession] case created => $createdCaseId');
      }

      caseId = createdCaseId;
      lastStatus = (data['status'] ?? 'Pending').toString();

      starting = false;
      tracking = true;
      notifyListeners();

      await realtime.watchCase(createdCaseId);

      if (createdCaseId.startsWith('CL')) {
        if (kDebugMode) {
          print('[DeviceSession] CL case detected, watching case room');
          print('[DeviceSession] auto-start WebRTC media for CL case');
        }

        await audioRealtime.watchCase(createdCaseId);
        await _startMediaIfNeeded(createdCaseId);
      }

      await _sendOneTick();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!tracking) return;
        if (_tickInFlight) return;

        _tickInFlight = true;
        try {
          await _sendOneTick();
        } finally {
          _tickInFlight = false;
        }
      });

      return true;
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = (resp is Map && resp['message'] != null)
          ? resp['message'].toString()
          : (e.message ?? 'Failed to start case.');

      _setError(msg);

      starting = false;
      tracking = false;
      caseId = null;
      this.caseName = null;

      _timer?.cancel();
      _timer = null;

      await realtime.unwatchCase();
      await audioRealtime.unwatchCase();
      await liveMediaWebRtcService.stop(onStateChanged: notifyListeners);

      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[DeviceSession] startCase error => $e');
      }

      _setError('Failed to start case.');

      starting = false;
      tracking = false;
      caseId = null;
      this.caseName = null;

      _timer?.cancel();
      _timer = null;

      await realtime.unwatchCase();
      await audioRealtime.unwatchCase();
      await liveMediaWebRtcService.stop(onStateChanged: notifyListeners);

      notifyListeners();
      return false;
    }
  }

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
      if (kDebugMode) {
        print('[DeviceSession] location tick failed => $e');
      }
      failedUpdates++;
      notifyListeners();
    }
  }

  Future<void> _startMediaIfNeeded(String id) async {
    if (kDebugMode) {
      print('[DeviceSession] _startMediaIfNeeded => $id');
    }

    if (!id.startsWith('CL')) return;
    if (audioActive) return;

    await liveMediaWebRtcService.start(
      caseId: id,
      onError: (msg) {
        if (kDebugMode) {
          print('[DeviceSession] media error => $msg');
        }
        _setMediaError(msg);
      },
      onStateChanged: notifyListeners,
    );

    audioActive = liveMediaWebRtcService.isStarted;

    if (kDebugMode) {
      print('[DeviceSession] media active => $audioActive');
    }

    notifyListeners();
  }

  Future<void> _stopAudio() async {
    if (kDebugMode) {
      print('[DeviceSession] _stopAudio');
    }

    await liveMediaWebRtcService.stop(onStateChanged: notifyListeners);
    audioActive = false;
    notifyListeners();
  }

  Future<void> stopTracking({bool clearCase = false}) async {
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
      if (kDebugMode) {
        print('[DeviceSession] updateFinalStatus error => $e');
      }
      _setError('Failed to update status.');
      statusUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void _onRealtimeUpdate(CaseUpdateEvent event) async {
    final id = caseId;
    if (id == null) return;
    if (event.caseId != id) return;

    if (kDebugMode) {
      print('[DeviceSession] case realtime update => ${event.status}');
    }

    lastStatus = event.status;

    if (_finalStatuses.contains(event.status)) {
      remotelyClosedStatus = event.status;
      await stopTracking(clearCase: true);
      return;
    }

    notifyListeners();
  }

  void _onAudioEnded(AudioStreamEndedEvent event) async {
    final id = caseId;

    if (kDebugMode) {
      print(
        '[DeviceSession] audio ended => currentCase=$id, eventCase=${event.caseId}',
      );
    }

    if (id == null) return;
    if (event.caseId != null && event.caseId != id) return;

    await _stopAudio();
  }

  void _onWebRtcAnswer(WebRtcAnswerEvent event) async {
    final id = caseId;
    if (id == null || event.caseId != id) return;

    if (kDebugMode) {
      print('[DeviceSession] received WebRTC answer');
    }

    await liveMediaWebRtcService.handleAnswer(
      event.sdpOrAnswer,
      onStateChanged: notifyListeners,
    );
  }

  void _onWebRtcIce(WebRtcIceCandidateEvent event) async {
    final id = caseId;
    if (id == null || event.caseId != id) return;

    if (kDebugMode) {
      print('[DeviceSession] received remote ICE');
    }

    await liveMediaWebRtcService.handleRemoteIceCandidate(
      event.candidate,
      onStateChanged: notifyListeners,
    );
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    _audioEndedSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
    liveMediaWebRtcService.dispose();
    super.dispose();
  }
}


//for 5sec data send//
// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:skudyx/core/realtime/case_audio_realtime_service.dart';
// import 'package:skudyx/core/realtime/case_realtime_service.dart';
// import 'package:skudyx/features/cases/data/remote/case_api.dart';
// import 'package:skudyx/features/cases/domain/services/live_media_webrtc_service.dart';
// import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';

// class DeviceSessionController extends ChangeNotifier {
//   final CaseApi caseApi;
//   final CaseRealtimeService realtime;
//   final CaseAudioRealtimeService audioRealtime;
//   final LiveMediaWebRtcService liveMediaWebRtcService;

//   DeviceSessionController({
//     required this.caseApi,
//     required this.realtime,
//     required this.audioRealtime,
//     required this.liveMediaWebRtcService,
//   }) {
//     _rtSub = realtime.stream.listen(_onRealtimeUpdate);
//     _audioEndedSub = audioRealtime.endedStream.listen(_onAudioEnded);
//     _answerSub = audioRealtime.answerStream.listen(_onWebRtcAnswer);
//     _iceSub = audioRealtime.iceCandidateStream.listen(_onWebRtcIce);
//   }

//   FoundDevice? connectedDevice;
//   bool get isConnected => connectedDevice != null;

//   bool starting = false;
//   bool tracking = false;

//   String? caseId;
//   String? caseName;
//   String? lastError;
//   String? lastStatus;
//   String? remotelyClosedStatus;

//   bool audioActive = false;
//   String? lastAudioError;

//   Timer? _timer;
//   bool _tickInFlight = false;

//   int successUpdates = 0;
//   int failedUpdates = 0;

//   bool statusUpdating = false;

//   final List<Map<String, dynamic>> coordinates = [];

//   StreamSubscription<CaseUpdateEvent>? _rtSub;
//   StreamSubscription<AudioStreamEndedEvent>? _audioEndedSub;
//   StreamSubscription<WebRtcAnswerEvent>? _answerSub;
//   StreamSubscription<WebRtcIceCandidateEvent>? _iceSub;

//   static const _finalStatuses = {'Resolved', 'Unresolved', 'False'};

//   bool get webrtcMicPermissionGranted =>
//       liveMediaWebRtcService.micPermissionGranted;
//   bool get webrtcCameraPermissionGranted =>
//       liveMediaWebRtcService.cameraPermissionGranted;
//   bool get webrtcLocalStreamAcquired =>
//       liveMediaWebRtcService.localStreamAcquired;
//   bool get webrtcHasLocalAudioTrack =>
//       liveMediaWebRtcService.hasLocalAudioTrack;
//   bool get webrtcHasLocalVideoTrack =>
//       liveMediaWebRtcService.hasLocalVideoTrack;
//   bool get webrtcOfferSent => liveMediaWebRtcService.offerSent;
//   bool get webrtcAnswerReceived => liveMediaWebRtcService.answerReceived;
//   int get webrtcSentIceCandidates => liveMediaWebRtcService.sentIceCandidates;
//   int get webrtcReceivedIceCandidates =>
//       liveMediaWebRtcService.receivedIceCandidates;
//   String get webrtcSignalingState => liveMediaWebRtcService.signalingState;
//   String get webrtcIceConnectionState =>
//       liveMediaWebRtcService.iceConnectionState;
//   String get webrtcConnectionState => liveMediaWebRtcService.connectionState;
//   String? get webrtcLastError => liveMediaWebRtcService.lastError;
//   MediaStream? get localPreviewStream => liveMediaWebRtcService.localStream;

//   void connectDevice(FoundDevice device) {
//     connectedDevice = device;
//     notifyListeners();
//   }

//   Future<void> disconnectDevice() async {
//     remotelyClosedStatus = null;
//     await stopTracking(clearCase: true);
//     connectedDevice = null;
//     notifyListeners();
//   }

//   void clearRemotelyClosedStatus() {
//     remotelyClosedStatus = null;
//   }

//   void _setError(String msg) {
//     lastError = msg;
//     notifyListeners();
//   }

//   void _setMediaError(String msg) {
//     lastAudioError = msg;
//     notifyListeners();
//   }

//   void clearError() {
//     lastError = null;
//     notifyListeners();
//   }

//   Future<bool> _ensureLocationReady() async {
//     final enabled = await Geolocator.isLocationServiceEnabled();
//     if (!enabled) {
//       _setError('Location services are disabled.');
//       return false;
//     }

//     var permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       _setError('Location permission denied.');
//       return false;
//     }

//     return true;
//   }

//   Future<Position> _getCurrentPosition() {
//     return Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//       timeLimit: const Duration(seconds: 10),
//     );
//   }

//   Future<bool> startCase({
//     required bool isTest,
//     required String caseName,
//   }) async {
//     if (!isConnected) {
//       _setError('No device connected.');
//       return false;
//     }

//     if (starting || tracking) return false;

//     clearError();
//     lastAudioError = null;
//     audioActive = false;

//     final ok = await _ensureLocationReady();
//     if (!ok) return false;

//     starting = true;
//     tracking = false;

//     this.caseName = caseName;
//     caseId = null;
//     lastStatus = null;
//     remotelyClosedStatus = null;

//     successUpdates = 0;
//     failedUpdates = 0;
//     coordinates.clear();

//     notifyListeners();

//     try {
//       final firstPos = await _getCurrentPosition();

//       final data = await caseApi.triggerCase(
//         latitude: firstPos.latitude,
//         longitude: firstPos.longitude,
//         isTest: isTest,
//       );

//       final createdCaseId = (data['case_id'] ?? '').toString();
//       if (createdCaseId.isEmpty) {
//         throw Exception('Missing case_id');
//       }

//       if (kDebugMode) {
//         print('[DeviceSession] case created => $createdCaseId');
//       }

//       caseId = createdCaseId;
//       lastStatus = (data['status'] ?? 'Pending').toString();

//       starting = false;
//       tracking = true;
//       notifyListeners();

//       await realtime.watchCase(createdCaseId);

//       if (createdCaseId.startsWith('CL')) {
//         if (kDebugMode) {
//           print('[DeviceSession] CL case detected, watching case room');
//           print('[DeviceSession] auto-start WebRTC media for CL case');
//         }

//         await audioRealtime.watchCase(createdCaseId);
//         await _startMediaIfNeeded(createdCaseId);
//       }

//       await _sendOneTick();

//       _timer?.cancel();
//       _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
//         if (!tracking) return;
//         if (_tickInFlight) return;

//         _tickInFlight = true;
//         try {
//           await _sendOneTick();
//         } finally {
//           _tickInFlight = false;
//         }
//       });

//       return true;
//     } on DioException catch (e) {
//       final resp = e.response?.data;
//       final msg = (resp is Map && resp['message'] != null)
//           ? resp['message'].toString()
//           : (e.message ?? 'Failed to start case.');

//       _setError(msg);

//       starting = false;
//       tracking = false;
//       caseId = null;
//       this.caseName = null;

//       _timer?.cancel();
//       _timer = null;

//       await realtime.unwatchCase();
//       await audioRealtime.unwatchCase();
//       await liveMediaWebRtcService.stop(onStateChanged: notifyListeners);

//       notifyListeners();
//       return false;
//     } catch (e) {
//       if (kDebugMode) {
//         print('[DeviceSession] startCase error => $e');
//       }

//       _setError('Failed to start case.');

//       starting = false;
//       tracking = false;
//       caseId = null;
//       this.caseName = null;

//       _timer?.cancel();
//       _timer = null;

//       await realtime.unwatchCase();
//       await audioRealtime.unwatchCase();
//       await liveMediaWebRtcService.stop(onStateChanged: notifyListeners);

//       notifyListeners();
//       return false;
//     }
//   }

//   Future<void> _sendOneTick() async {
//     final id = caseId;
//     if (id == null || !tracking) return;

//     try {
//       final pos = await _getCurrentPosition();

//       coordinates.add({
//         'latitude': pos.latitude,
//         'longitude': pos.longitude,
//         'timestamp': DateTime.now().toIso8601String(),
//       });

//       await caseApi.updateLocation(
//         caseId: id,
//         latitude: pos.latitude,
//         longitude: pos.longitude,
//       );

//       successUpdates++;
//       notifyListeners();
//     } catch (e) {
//       if (kDebugMode) {
//         print('[DeviceSession] location tick failed => $e');
//       }
//       failedUpdates++;
//       notifyListeners();
//     }
//   }

//   Future<void> _startMediaIfNeeded(String id) async {
//     if (kDebugMode) {
//       print('[DeviceSession] _startMediaIfNeeded => $id');
//     }

//     if (!id.startsWith('CL')) return;
//     if (audioActive) return;

//     await liveMediaWebRtcService.start(
//       caseId: id,
//       onError: (msg) {
//         if (kDebugMode) {
//           print('[DeviceSession] media error => $msg');
//         }
//         _setMediaError(msg);
//       },
//       onStateChanged: notifyListeners,
//     );

//     audioActive = liveMediaWebRtcService.isStarted;

//     if (kDebugMode) {
//       print('[DeviceSession] media active => $audioActive');
//     }

//     notifyListeners();
//   }

//   Future<void> _stopAudio() async {
//     if (kDebugMode) {
//       print('[DeviceSession] _stopAudio');
//     }

//     await liveMediaWebRtcService.stop(onStateChanged: notifyListeners);
//     audioActive = false;
//     notifyListeners();
//   }

//   Future<void> stopTracking({bool clearCase = false}) async {
//     _timer?.cancel();
//     _timer = null;
//     _tickInFlight = false;

//     starting = false;
//     tracking = false;

//     await realtime.unwatchCase();
//     await audioRealtime.unwatchCase();
//     await _stopAudio();

//     if (clearCase) {
//       caseId = null;
//       caseName = null;
//       lastStatus = null;
//       successUpdates = 0;
//       failedUpdates = 0;
//       coordinates.clear();
//       lastError = null;
//     }

//     notifyListeners();
//   }

//   Future<bool> updateFinalStatus({
//     required String status,
//     required String note,
//   }) async {
//     final id = caseId;
//     if (id == null || id.isEmpty) {
//       _setError('No active case.');
//       return false;
//     }

//     if (statusUpdating) return false;

//     clearError();
//     statusUpdating = true;
//     notifyListeners();

//     try {
//       await caseApi.updateStatus(caseId: id, status: status, note: note);

//       lastStatus = status;
//       remotelyClosedStatus = null;

//       await stopTracking(clearCase: true);

//       statusUpdating = false;
//       notifyListeners();
//       return true;
//     } on DioException catch (e) {
//       final resp = e.response?.data;
//       final msg = (resp is Map && resp['message'] != null)
//           ? resp['message'].toString()
//           : (e.message ?? 'Failed to update status.');

//       _setError(msg);
//       statusUpdating = false;
//       notifyListeners();
//       return false;
//     } catch (e) {
//       if (kDebugMode) {
//         print('[DeviceSession] updateFinalStatus error => $e');
//       }
//       _setError('Failed to update status.');
//       statusUpdating = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   void _onRealtimeUpdate(CaseUpdateEvent event) async {
//     final id = caseId;
//     if (id == null) return;
//     if (event.caseId != id) return;

//     if (kDebugMode) {
//       print('[DeviceSession] case realtime update => ${event.status}');
//     }

//     lastStatus = event.status;

//     if (_finalStatuses.contains(event.status)) {
//       remotelyClosedStatus = event.status;
//       await stopTracking(clearCase: true);
//       return;
//     }

//     notifyListeners();
//   }

//   void _onAudioEnded(AudioStreamEndedEvent event) async {
//     final id = caseId;

//     if (kDebugMode) {
//       print(
//         '[DeviceSession] audio ended => currentCase=$id, eventCase=${event.caseId}',
//       );
//     }

//     if (id == null) return;
//     if (event.caseId != null && event.caseId != id) return;

//     await _stopAudio();
//   }

//   void _onWebRtcAnswer(WebRtcAnswerEvent event) async {
//     final id = caseId;
//     if (id == null || event.caseId != id) return;

//     if (kDebugMode) {
//       print('[DeviceSession] received WebRTC answer');
//     }

//     await liveMediaWebRtcService.handleAnswer(
//       event.sdpOrAnswer,
//       onStateChanged: notifyListeners,
//     );
//   }

//   void _onWebRtcIce(WebRtcIceCandidateEvent event) async {
//     final id = caseId;
//     if (id == null || event.caseId != id) return;

//     if (kDebugMode) {
//       print('[DeviceSession] received remote ICE');
//     }

//     await liveMediaWebRtcService.handleRemoteIceCandidate(
//       event.candidate,
//       onStateChanged: notifyListeners,
//     );
//   }

//   @override
//   void dispose() {
//     _rtSub?.cancel();
//     _audioEndedSub?.cancel();
//     _answerSub?.cancel();
//     _iceSub?.cancel();
//     liveMediaWebRtcService.dispose();
//     super.dispose();
//   }
// }