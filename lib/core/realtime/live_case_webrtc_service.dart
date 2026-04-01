import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LiveCaseWebRtcService {
  final String socketBaseUrl;
  final String uploadBaseUrl;
  final String caseId;
  final bool isCaller;

  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final AudioRecorder _recorder = AudioRecorder();
  String? _recordedFilePath;

  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<bool> isInCall = ValueNotifier(false);
  final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final ValueNotifier<String?> m3u8Url = ValueNotifier(null);

  Function(MediaStream stream)? onRemoteStream;

  LiveCaseWebRtcService({
    required this.socketBaseUrl,
    required this.uploadBaseUrl,
    required this.caseId,
    required this.isCaller,
  });

  Future<void> initialize() async {
    await _connectSocket();
  }

  Future<void> _connectSocket() async {
    _socket = IO.io(
      socketBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) async {
      debugPrint("Socket connected: ${_socket?.id}");
      isConnected.value = true;

      _socket!.emit("join_case", {
        "case_id": caseId,
        "role": isCaller ? "user" : "agent",
      });

      await _initializePeerConnection();

      if (isCaller) {
        await _createAndSendOffer();
      }
    });

    _socket!.on("participant_joined", (data) async {
      debugPrint("Participant joined: $data");
    });

    _socket!.on("webrtc_offer", (data) async {
      try {
        debugPrint("Received offer");
        final sdp = data["sdp"];
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(sdp["sdp"], sdp["type"]),
        );

        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        _socket!.emit("webrtc_answer", {
          "case_id": caseId,
          "answer": {"sdp": answer.sdp, "type": answer.type},
        });

        isInCall.value = true;
      } catch (e) {
        debugPrint("Offer handling error: $e");
      }
    });

    _socket!.on("webrtc_answer", (data) async {
      try {
        debugPrint("Received answer");
        final sdp = data["sdp"];
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(sdp["sdp"], sdp["type"]),
        );
        isInCall.value = true;
      } catch (e) {
        debugPrint("Answer handling error: $e");
      }
    });

    _socket!.on("webrtc_ice_candidate", (data) async {
      try {
        final candidate = data["candidate"];
        await _peerConnection?.addCandidate(
          RTCIceCandidate(
            candidate["candidate"],
            candidate["sdpMid"],
            candidate["sdpMLineIndex"],
          ),
        );
      } catch (e) {
        debugPrint("ICE candidate error: $e");
      }
    });

    _socket!.on("audio_stream_ended", (data) {
      debugPrint("Audio stream ended: $data");
      m3u8Url.value = data["m3u8_url"];
    });

    _socket!.onDisconnect((_) {
      debugPrint("Socket disconnected");
      isConnected.value = false;
      isInCall.value = false;
    });

    _socket!.connect();
  }

  Future<void> _initializePeerConnection() async {
    final configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _localStream = await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": false,
    });

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _socket?.emit("webrtc_ice_candidate", {
        "case_id": caseId,
        "candidate": {
          "candidate": candidate.candidate,
          "sdpMid": candidate.sdpMid,
          "sdpMLineIndex": candidate.sdpMLineIndex,
        },
      });
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint("Peer connection state: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        isInCall.value = true;
      }
    };
  }

  Future<void> _createAndSendOffer() async {
    final offer = await _peerConnection!.createOffer({
      "offerToReceiveAudio": true,
      "offerToReceiveVideo": false,
    });

    await _peerConnection!.setLocalDescription(offer);

    _socket!.emit("webrtc_offer", {
      "case_id": caseId,
      "offer": {"sdp": offer.sdp, "type": offer.type},
    });
  }

  Future<void> startLocalRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/case_audio_$caseId.m4a";
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

      isRecording.value = true;
      debugPrint("Recording started at: $path");
    } catch (e) {
      debugPrint("Recording start error: $e");
    }
  }

  Future<String?> stopLocalRecording() async {
    try {
      final path = await _recorder.stop();
      isRecording.value = false;
      debugPrint("Recording stopped: $path");
      return path;
    } catch (e) {
      debugPrint("Recording stop error: $e");
      return null;
    }
  }

  Future<String?> uploadRecordedFile({
    required String uploadEndpoint,
    String fileFieldName = "audio",
  }) async {
    try {
      final path = _recordedFilePath;
      if (path == null) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final dio = Dio();

      final formData = FormData.fromMap({
        "case_id": caseId,
        fileFieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await dio.post(
        "$uploadBaseUrl$uploadEndpoint",
        data: formData,
      );

      debugPrint("Upload response: ${response.data}");

      if (response.data is Map && response.data["m3u8_url"] != null) {
        m3u8Url.value = response.data["m3u8_url"];
        return response.data["m3u8_url"];
      }

      return null;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> endLiveCase({required String uploadEndpoint}) async {
    await stopLocalRecording();
    await uploadRecordedFile(uploadEndpoint: uploadEndpoint);

    _socket?.emit("stop_audio_stream", {"case_id": caseId});

    await dispose();
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();

      for (final track in _localStream?.getTracks() ?? []) {
        await track.stop();
      }

      for (final track in _remoteStream?.getTracks() ?? []) {
        await track.stop();
      }

      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _peerConnection?.close();

      _socket?.disconnect();
      _socket?.dispose();

      isConnected.dispose();
      isInCall.dispose();
      isRecording.dispose();
      m3u8Url.dispose();
    } catch (_) {}
  }
}
