import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class LiveCaseCallController extends ChangeNotifier {
  final String socketBaseUrl;
  final String uploadBaseUrl;
  final String uploadEndpoint;
  final String caseId;
  final bool isCaller;

  LiveCaseCallController({
    required this.socketBaseUrl,
    required this.uploadBaseUrl,
    required this.uploadEndpoint,
    required this.caseId,
    required this.isCaller,
  });

  io.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final AudioRecorder _recorder = AudioRecorder();
  String? _recordedFilePath;

  bool connecting = false;
  bool connected = false;
  bool inCall = false;
  bool recording = false;
  bool ending = false;

  String? lastError;
  String? m3u8Url;
  String? remoteSocketId;

  MediaStream? get remoteStream => _remoteStream;

  Future<void> start() async {
    if (connecting || connected) return;

    connecting = true;
    lastError = null;
    notifyListeners();

    try {
      await _connectSocket();
      await _startLocalRecording();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  Future<void> _connectSocket() async {
    final completer = Completer<void>();

    _socket = io.io(
      socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) async {
      connected = true;
      notifyListeners();

      _socket!.emit('join_case', {
        'case_id': caseId,
        'role': isCaller ? 'user' : 'agent',
      });

      await _initPeerConnection();

      if (isCaller) {
        await _createOffer();
      }

      if (!completer.isCompleted) completer.complete();
    });

    _socket!.on('participant_joined', (data) {
      remoteSocketId = data?['socket_id']?.toString();
      notifyListeners();
    });

    _socket!.on('webrtc_offer', (data) async {
      try {
        final sdp = data['sdp'];
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(sdp['sdp'], sdp['type']),
        );

        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        _socket!.emit('webrtc_answer', {
          'case_id': caseId,
          'answer': {'sdp': answer.sdp, 'type': answer.type},
        });

        inCall = true;
        notifyListeners();
      } catch (e) {
        lastError = 'Offer error: $e';
        notifyListeners();
      }
    });

    _socket!.on('webrtc_answer', (data) async {
      try {
        final sdp = data['sdp'];
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(sdp['sdp'], sdp['type']),
        );
        inCall = true;
        notifyListeners();
      } catch (e) {
        lastError = 'Answer error: $e';
        notifyListeners();
      }
    });

    _socket!.on('webrtc_ice_candidate', (data) async {
      try {
        final candidate = data['candidate'];
        await _peerConnection?.addCandidate(
          RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ),
        );
      } catch (e) {
        lastError = 'ICE error: $e';
        notifyListeners();
      }
    });

    _socket!.on('audio_stream_ended', (data) {
      m3u8Url = data?['m3u8_url']?.toString();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      connected = false;
      inCall = false;
      notifyListeners();
    });

    _socket!.connect();

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Socket connection timeout');
      },
    );
  }

  Future<void> _initPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onIceCandidate = (candidate) {
      _socket?.emit('webrtc_ice_candidate', {
        'case_id': caseId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        notifyListeners();
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        inCall = true;
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        inCall = false;
      }
      notifyListeners();
    };
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    await _peerConnection!.setLocalDescription(offer);

    _socket!.emit('webrtc_offer', {
      'case_id': caseId,
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  Future<void> _startLocalRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/case_audio_$caseId.m4a';
    _recordedFilePath = path;

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    recording = true;
    notifyListeners();
  }

  Future<String?> stopLocalRecording() async {
    try {
      final path = await _recorder.stop();
      recording = false;
      notifyListeners();
      return path;
    } catch (e) {
      lastError = 'Stop recording failed: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> uploadFinalAudio() async {
    try {
      final path = _recordedFilePath;
      if (path == null) return null;

      final file = File(path);
      if (!await file.exists()) {
        lastError = 'Recorded audio file not found';
        notifyListeners();
        return null;
      }

      final dio = Dio();

      final formData = FormData.fromMap({
        'case_id': caseId,
        'audio': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await dio.post(
        '$uploadBaseUrl$uploadEndpoint',
        data: formData,
      );

      final data = response.data;
      if (data is Map && data['m3u8_url'] != null) {
        m3u8Url = data['m3u8_url'].toString();
        notifyListeners();
        return m3u8Url;
      }

      return null;
    } catch (e) {
      lastError = 'Upload failed: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> endCallAndUpload() async {
    if (ending) return;
    ending = true;
    notifyListeners();

    try {
      await stopLocalRecording();
      await uploadFinalAudio();

      _socket?.emit('stop_audio_stream', {'case_id': caseId});
    } catch (e) {
      lastError = 'End call failed: $e';
      notifyListeners();
    } finally {
      ending = false;
      notifyListeners();
    }
  }

  Future<void> disposeCall() async {
    try {
      await _recorder.dispose();

      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }

      for (final track in _remoteStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }

      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _peerConnection?.close();

      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    disposeCall();
    super.dispose();
  }
}
