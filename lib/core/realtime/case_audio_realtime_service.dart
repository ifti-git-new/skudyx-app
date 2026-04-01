import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:skudyx/core/config/app_config.dart';
import 'package:skudyx/core/storage/auth_token_storage.dart';

class EmergencyAudioSignalEvent {
  final String? caseId;
  final bool shouldStartAudio;

  EmergencyAudioSignalEvent({
    required this.caseId,
    required this.shouldStartAudio,
  });
}

class AudioStreamEndedEvent {
  final String? caseId;

  AudioStreamEndedEvent({required this.caseId});
}

class CaseAudioRealtimeService {
  final AppConfig config;
  final AuthTokenStorage tokenStorage;

  CaseAudioRealtimeService({required this.config, required this.tokenStorage});

  IO.Socket? _socket;
  String? _watchingCaseId;

  final _emergencyController =
      StreamController<EmergencyAudioSignalEvent>.broadcast();
  final _endedController = StreamController<AudioStreamEndedEvent>.broadcast();

  Stream<EmergencyAudioSignalEvent> get emergencyStream =>
      _emergencyController.stream;
  Stream<AudioStreamEndedEvent> get endedStream => _endedController.stream;

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

      final caseId = _watchingCaseId;
      if (caseId != null) {
        if (kDebugMode) {
          print('[AudioSocket] join_case => $caseId');
        }
        socket.emit('join_case', caseId);
      }
    });

    socket.onAny((event, data) {
      if (kDebugMode) {
        print('[AudioSocket][ANY] event=$event data=$data');
      }
    });

    socket.on('emergency_response', (data) {
      if (kDebugMode) {
        print('[AudioSocket] emergency_response => $data');
      }

      if (data is Map) {
        _emergencyController.add(
          EmergencyAudioSignalEvent(
            caseId: data['case_id']?.toString(),
            shouldStartAudio: data['should_start_audio'] == true,
          ),
        );
      } else {
        _emergencyController.add(
          EmergencyAudioSignalEvent(
            caseId: _watchingCaseId,
            shouldStartAudio: false,
          ),
        );
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

    if (kDebugMode) {
      print('[AudioSocket] watchCase => $caseId');
    }

    _socket?.emit('join_case', caseId);
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
    await _emergencyController.close();
    await _endedController.close();
  }
}
