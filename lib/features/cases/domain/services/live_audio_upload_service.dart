import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skudyx/features/cases/data/remote/audio_upload_api.dart';

class LiveAudioUploadService {
  final AudioUploadApi audioUploadApi;

  LiveAudioUploadService({required this.audioUploadApi});

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _initialized = false;
  bool _running = false;
  bool _busy = false;
  String? _currentCaseId;
  Timer? _loopTimer;

  bool get isRunning => _running;

  Future<void> _ensureInit() async {
    if (_initialized) return;

    if (kDebugMode) {
      print('[LiveAudio] opening recorder');
    }

    await _recorder.openRecorder();
    _initialized = true;
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    if (kDebugMode) {
      print('[LiveAudio] mic permission => $status');
    }
    return status.isGranted;
  }

  Future<void> start({
    required String caseId,
    Duration chunkDuration = const Duration(seconds: 2),
    void Function(String error)? onError,
  }) async {
    if (kDebugMode) {
      print('[LiveAudio] start requested => $caseId');
    }

    if (_running) {
      if (kDebugMode) {
        print('[LiveAudio] already running');
      }
      return;
    }

    final granted = await _ensureMicPermission();
    if (!granted) {
      onError?.call('Microphone permission denied.');
      return;
    }

    await _ensureInit();

    _currentCaseId = caseId;
    _running = true;

    await _recordAndUploadChunk(chunkDuration, onError);

    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(chunkDuration, (_) async {
      if (!_running || _busy) return;
      await _recordAndUploadChunk(chunkDuration, onError);
    });
  }

  Future<void> _recordAndUploadChunk(
    Duration chunkDuration,
    void Function(String error)? onError,
  ) async {
    final caseId = _currentCaseId;
    if (!_running || caseId == null) return;

    _busy = true;

    File? file;
    try {
      final dir = await getTemporaryDirectory();
      final fileName = '${caseId}_${DateTime.now().millisecondsSinceEpoch}.wav';
      final path = p.join(dir.path, fileName);
      file = File(path);

      if (kDebugMode) {
        print('[LiveAudio] recording chunk => $path');
      }

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      await Future.delayed(chunkDuration);

      await _recorder.stopRecorder();

      if (!await file.exists()) {
        throw Exception('Recorded chunk file not found.');
      }

      if (kDebugMode) {
        print('[LiveAudio] uploading chunk => ${file.path}');
      }

      final res = await audioUploadApi.uploadAudio(
        caseId: caseId,
        audioFile: file,
      );

      if (kDebugMode) {
        print('[LiveAudio] upload success => $res');
      }

      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('[LiveAudio] temp file deleted => ${file.path}');
        }
      }
    } catch (e) {
      try {
        if (_recorder.isRecording) {
          await _recorder.stopRecorder();
        }
      } catch (_) {}

      final msg = 'Audio upload failed: $e';
      if (kDebugMode) {
        print('[LiveAudio] $msg');
      }
      onError?.call(msg);
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    if (kDebugMode) {
      print('[LiveAudio] stop requested');
    }

    _running = false;
    _currentCaseId = null;

    _loopTimer?.cancel();
    _loopTimer = null;

    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();

    if (_initialized) {
      if (kDebugMode) {
        print('[LiveAudio] closing recorder');
      }
      await _recorder.closeRecorder();
      _initialized = false;
    }
  }
}
