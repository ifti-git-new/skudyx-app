// lib/features/cases/domain/services/websocket_audio_stream_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';

class WebSocketAudioStreamService {
  WebSocketChannel? _channel;
  AudioRecorder? _recorder;
  StreamSubscription<List<int>>? _audioStreamSub;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  Timer? _pingTimer; // Add ping timer
  bool _isRecording = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _intentionallyStopped = false;
  String? _currentCaseId;
  int _chunkCount = 0;
  int _totalBytesSent = 0;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const String _wsUrl =
      'wss://skudyx-backend-c8do.onrender.com/ws/audio-stream';

  final _log = (String msg) {
    if (kDebugMode) print('🎙️ [WebSocket Audio] $msg');
  };

  bool get isStreaming => _isRecording && _isConnected;
  String? get currentCaseId => _currentCaseId;
  int get chunkCount => _chunkCount;
  int get totalBytesSent => _totalBytesSent;
  bool get isConnected => _isConnected;

  Future<void> connect({required String caseId}) async {
    if (_isConnecting || _isConnected) {
      _log('⚠️ Already connecting or connected');
      return;
    }

    _intentionallyStopped = false;
    _isConnecting = true;
    _currentCaseId = caseId;

    try {
      _log('🔌 Connecting to WebSocket audio stream...');
      _log('📡 URL: $_wsUrl');
      _log('📋 Case ID: $caseId');

      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      await _channel!.ready.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('WebSocket connection timeout'),
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _log('✅ WebSocket connected successfully!');
      _log('📤 Sending join message as sender...');

      _channel!.sink.add(
        jsonEncode({'type': 'join', 'caseId': caseId, 'isSender': true}),
      );

      _log('✅ Join message sent');

      _listenToMessages();
      _startHealthCheck();
      _startPing(); // Start ping to keep connection alive
    } catch (e, stack) {
      _isConnecting = false;
      _log('❌ Connection failed: $e');
      _log('❌ Stack: $stack');
      _handleConnectionError();
      rethrow;
    }
  }

  // Add ping to keep connection alive
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _channel != null && !_intentionallyStopped) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
          _log('🏓 Sent ping');
        } catch (e) {
          _log('❌ Ping failed: $e');
        }
      }
    });
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_intentionallyStopped) return;

      if (!_isConnected && _currentCaseId != null) {
        _log('🩺 [HealthCheck] Connection lost — triggering reconnect');
        _handleConnectionError();
      }
    });
  }

  void _handleConnectionError() {
    _isConnected = false;

    if (_intentionallyStopped) return;

    if (_reconnectAttempts < _maxReconnectAttempts && _currentCaseId != null) {
      _reconnectAttempts++;
      final delaySecs = (_reconnectAttempts * 2).clamp(2, 15);
      final delay = Duration(seconds: delaySecs);

      _log(
        '🔄 Reconnecting in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts/$_maxReconnectAttempts)...',
      );

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () async {
        if (_intentionallyStopped || _currentCaseId == null) return;

        _log('🔄 Attempting reconnect...');
        try {
          await _channel?.sink.close();
          _channel = null;
          _isConnecting = false;
          await connect(caseId: _currentCaseId!);
        } catch (e) {
          _log('❌ Reconnection failed: $e');
          _handleConnectionError();
        }
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('❌ Max reconnection attempts reached. Streaming stopped.');
      _isRecording = false;
    }
  }

  void _listenToMessages() {
    _log('👂 Starting to listen for WebSocket messages...');

    _channel!.stream.listen(
      (message) {
        try {
          _log(
            '📥 Received message: ${message.toString().substring(0, message.toString().length > 100 ? 100 : message.toString().length)}...',
          );

          final data = jsonDecode(message);
          _log('📨 Message type: ${data['type']}');

          if (data['type'] == 'joined') {
            _log('✅ Joined case: ${data['caseId']}');
            if (!_isRecording) {
              _log('🎬 Starting audio recording...');
              _startRecording();
            } else {
              _log('🎙️ Already recording — reconnected, continuing stream');
            }
          } else if (data['type'] == 'listener_update') {
            _log('👥 Listener update: count=${data['count']}');
          } else if (data['type'] == 'sender_left') {
            _log('⚠️ Sender left notification received');
          } else if (data['type'] == 'pong') {
            _log('🏓 Received pong');
          }
        } catch (e) {
          _log('❌ Message parse error: $e');
          _log('❌ Raw message: $message');
        }
      },
      onError: (error) {
        _log('❌ WebSocket error: $error');
        _isConnected = false;
        if (!_intentionallyStopped) _handleConnectionError();
      },
      onDone: () {
        _log('🔌 WebSocket connection closed');
        _isConnected = false;
        if (!_intentionallyStopped && _currentCaseId != null) {
          _handleConnectionError();
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _startRecording() async {
    if (_isRecording) {
      _log('⚠️ Already recording, skipping...');
      return;
    }

    _log('🎤 Initializing AudioRecorder...');
    _recorder = AudioRecorder();

    _log('🔐 Checking microphone permission...');
    final hasPermission = await _recorder!.hasPermission();
    _log('🔐 Permission status: $hasPermission');

    if (!hasPermission) {
      _log('❌ Microphone permission denied!');
      throw Exception('Microphone permission denied');
    }

    _log('🎙️ Starting audio recording...');
    _log('📊 Audio config:');
    _log('   - Encoder: PCM16');
    _log('   - Sample Rate: 44100 Hz');
    _log('   - Bit Rate: 128000');
    _log('   - Channels: 1 (Mono)');

    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    _isRecording = true;
    _chunkCount = 0;
    _totalBytesSent = 0;

    _log('✅ Recording started successfully!');
    _log('📡 Starting to stream audio chunks to WebSocket...');

    _audioStreamSub = stream.listen(
      (data) {
        // Always send if recording, even if temporarily disconnected
        if (_channel != null) {
          _chunkCount++;
          _totalBytesSent += data.length;

          final chunkBase64 = base64Encode(Uint8List.fromList(data));

          try {
            _channel!.sink.add(
              jsonEncode({
                'type': 'audio_chunk',
                'chunk': chunkBase64,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'chunkIndex': _chunkCount,
              }),
            );

            if (_chunkCount % 10 == 0) {
              _log('📤 Sent chunk #$_chunkCount (${data.length} bytes)');
              _log(
                '📊 Total chunks: $_chunkCount, Total bytes: $_totalBytesSent',
              );
            }
          } catch (e) {
            _log('❌ Failed to send chunk: $e');
          }
        }
      },
      onError: (error) {
        _log('❌ Audio stream error: $error');
      },
      onDone: () {
        _log('🏁 Audio stream completed');
        _log('📊 Final stats:');
        _log('   - Total chunks: $_chunkCount');
        _log('   - Total bytes sent: $_totalBytesSent');
      },
    );

    _log('✅ Recording and streaming active!');
  }

  // Enhanced resume method
  Future<void> resumeIfNeeded() async {
    if (_intentionallyStopped) return;

    final caseId = _currentCaseId;
    if (caseId == null) return;

    _log('🔄 [Resume] Checking connection state...');

    // Force reconnection if not connected
    if (!_isConnected && !_isConnecting) {
      _log('🔄 [Resume] Forcing WebSocket & Audio reconnection...');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();

      try {
        // Clean up old connection
        await _channel?.sink.close();
        _channel = null;
        _isConnecting = false;

        // Stop recording if active
        if (_isRecording) {
          await _recorder?.stop();
          _isRecording = false;
        }

        // Reconnect
        await connect(caseId: caseId);
      } catch (e) {
        _log('❌ [Resume] Reconnect failed: $e');
      }
    } else {
      _log('✅ [Resume] Already connected — no action needed');
    }
  }

  Future<void> stop() async {
    _log('🛑 Stopping audio stream...');
    _intentionallyStopped = true;
    _isRecording = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;

    try {
      _log('⏹️ Stopping recorder...');
      if (_recorder != null && await _recorder!.isRecording()) {
        await _recorder!.stop();
      }
      _log('✅ Recorder stopped');
    } catch (e) {
      _log('⚠️ Error stopping recorder: $e');
    }

    try {
      _log('⏹️ Cancelling audio stream subscription...');
      await _audioStreamSub?.cancel();
      _log('✅ Audio stream subscription cancelled');
    } catch (e) {
      _log('⚠️ Error cancelling subscription: $e');
    }

    if (_channel != null && _currentCaseId != null) {
      try {
        _log('📤 Sending leave message...');
        _channel!.sink.add(
          jsonEncode({'type': 'leave', 'caseId': _currentCaseId}),
        );
        _log('✅ Leave message sent');
      } catch (e) {
        _log('⚠️ Error sending leave message: $e');
      }

      try {
        _log('🔌 Closing WebSocket connection...');
        await _channel?.sink.close();
        _log('✅ WebSocket closed');
      } catch (e) {
        _log('⚠️ Error closing WebSocket: $e');
      }
    }

    _isConnected = false;
    _isConnecting = false;
    _currentCaseId = null;

    _log('✅ Audio stream stopped completely');
  }

  Future<void> dispose() async {
    await stop();
    _recorder?.dispose();
  }
}
