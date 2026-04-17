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

  bool _isRecording = false;
  bool _isConnected = false;
  String? _currentCaseId;
  int _chunkCount = 0;
  int _totalBytesSent = 0;

  final _log = (String msg) {
    if (kDebugMode) print('🎙️ [WebSocket Audio] $msg');
  };

  // Getters for UI
  bool get isStreaming => _isRecording && _isConnected;
  String? get currentCaseId => _currentCaseId;
  int get chunkCount => _chunkCount;
  int get totalBytesSent => _totalBytesSent;
  bool get isConnected => _isConnected;

  // Connect to WebSocket audio server
  Future<void> connect({required String caseId}) async {
    try {
      _log('🔌 Connecting to WebSocket audio stream...');
      _log(
        '📡 WebSocket URL: wss://skudyx-backend-thtu.onrender.com/ws/audio-stream',
      );
      _log('📋 Case ID: $caseId');

      _channel = WebSocketChannel.connect(
        Uri.parse('wss://skudyx-backend-thtu.onrender.com/ws/audio-stream'),
      );

      // Wait for connection
      await _channel!.ready;
      _isConnected = true;
      _currentCaseId = caseId;

      _log('✅ WebSocket connected successfully!');
      _log('📤 Sending join message as sender...');

      // Join as sender
      _channel!.sink.add(
        jsonEncode({'type': 'join', 'caseId': caseId, 'isSender': true}),
      );

      _log('✅ Join message sent');

      // Listen for messages
      _listenToMessages();
    } catch (e, stackTrace) {
      _log('❌ Connection failed: $e');
      _log('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Listen to WebSocket messages
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
            _log('🎬 Starting audio recording...');
            _startRecording();
          } else if (data['type'] == 'sender_left') {
            _log('⚠️ Sender left notification received');
          }
        } catch (e) {
          _log('❌ Message parse error: $e');
          _log('❌ Raw message: $message');
        }
      },
      onError: (error) {
        _log('❌ WebSocket error: $error');
        // Mark as disconnected but don't stop recording
        _isConnected = false;
        // Attempt reconnection after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (_isRecording && _currentCaseId != null) {
            reconnectIfNeeded();
          }
        });
      },
      onDone: () {
        _log('🔌 WebSocket connection closed');
        _isConnected = false;
        // Attempt reconnection if still recording
        if (_isRecording && _currentCaseId != null) {
          Future.delayed(const Duration(seconds: 5), () {
            reconnectIfNeeded();
          });
        }
      },
      cancelOnError: false,
    );
  }

  // Reconnect if needed
  Future<void> reconnectIfNeeded() async {
    if (_isConnected && _channel != null) {
      // Already connected
      return;
    }

    if (_currentCaseId != null && _isRecording) {
      _log('🔄 [WebSocket Audio] Reconnecting after background...');
      try {
        await connect(caseId: _currentCaseId!);
        _log('✅ [WebSocket Audio] Reconnected successfully');
      } catch (e) {
        _log('❌ [WebSocket Audio] Reconnection failed: $e');
      }
    }
  }

  // Start recording and streaming audio
  Future<void> _startRecording() async {
    if (_isRecording) {
      _log('⚠️ Already recording, skipping...');
      return;
    }

    _log('🎤 Initializing AudioRecorder...');
    _recorder = AudioRecorder();

    // Check permissions
    _log('🔐 Checking microphone permission...');
    final hasPermission = await _recorder!.hasPermission();
    _log('🔐 Permission status: $hasPermission');

    if (hasPermission) {
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
        ),
      );

      _isRecording = true;
      _chunkCount = 0;
      _totalBytesSent = 0;

      _log('✅ Recording started successfully!');
      _log('📡 Starting to stream audio chunks to WebSocket...');

      // Stream audio chunks to WebSocket
      _audioStreamSub = stream.listen(
        (data) {
          if (_isConnected && _channel != null) {
            _chunkCount++;
            _totalBytesSent += data.length;

            // Send audio chunk as base64
            final chunkBase64 = base64Encode(Uint8List.fromList(data));

            _channel!.sink.add(
              jsonEncode({
                'type': 'audio_chunk',
                'chunk': chunkBase64,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'chunkIndex': _chunkCount,
              }),
            );

            // Log every 10 chunks to avoid spam
            if (_chunkCount % 10 == 0) {
              _log('📤 Sent chunk #$_chunkCount (${data.length} bytes)');
              _log(
                '📊 Total chunks: $_chunkCount, Total bytes: $_totalBytesSent',
              );
            }
          } else {
            _log('⚠️ Not connected, skipping chunk #${_chunkCount + 1}');
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
    } else {
      _log('❌ Microphone permission denied!');
      throw Exception('Microphone permission denied');
    }
  }

  // Stop streaming
  Future<void> stop() async {
    _log('🛑 Stopping audio stream...');

    _isRecording = false;

    // Stop recording
    try {
      _log('⏹️ Stopping recorder...');
      await _recorder?.stop();
      _log('✅ Recorder stopped');
    } catch (e) {
      _log('⚠️ Error stopping recorder: $e');
    }

    // Cancel audio stream subscription
    try {
      _log('⏹️ Cancelling audio stream subscription...');
      await _audioStreamSub?.cancel();
      _log('✅ Audio stream subscription cancelled');
    } catch (e) {
      _log('⚠️ Error cancelling subscription: $e');
    }

    // Leave case and close WebSocket
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
    _currentCaseId = null;
    _log('✅ Audio stream stopped completely');
  }
}
