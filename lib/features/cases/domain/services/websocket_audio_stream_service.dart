import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WebSocketAudioStreamService {
  WebSocketChannel? _channel;
  AudioRecorder? _recorder;
  StreamSubscription<List<int>>? _audioStreamSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  Timer? _connectionWatchdogTimer;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _waitingForNetwork = false;

  bool _isRecording = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _intentionallyStopped = false;
  bool _wasDisconnectedBySystem = false;

  String? _currentCaseId;
  int _chunkCount = 0;
  int _totalBytesSent = 0;
  int _reconnectAttempts = 0;

  static const int _maxReconnectAttempts = 15;
  static const String _wsUrl =
      'wss://skudyx-backend-c8do.onrender.com/ws/audio-stream';

  static const int _sampleRate = 44100;
  static const int _bitRate = 128000;
  static const int _numChannels = 1;

  final _log = (String msg) {
    if (kDebugMode) print('🎙️ [WebSocket Audio] $msg');
  };

  bool get isStreaming => _isRecording && _isConnected;
  String? get currentCaseId => _currentCaseId;
  int get chunkCount => _chunkCount;
  int get totalBytesSent => _totalBytesSent;
  bool get isConnected => _isConnected;

  // --------------------------------------------------------------
  // PUBLIC API
  // --------------------------------------------------------------
  Future<void> connect({required String caseId}) async {
    if (_isConnecting || _isConnected) {
      _log('⚠️ Already connecting or connected');
      return;
    }

    _intentionallyStopped = false;
    _wasDisconnectedBySystem = false;
    _isConnecting = true;
    _currentCaseId = caseId;

    _startConnectivityListener();

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
      _waitingForNetwork = false;

      _log('✅ WebSocket connected successfully!');

      _sendJoinMessage(caseId);
      _listenToMessages();
      _startHealthCheck();
      _startConnectionWatchdog();

      // Immediately restart recording pipeline for this new connection.
      await _restartRecording();
    } catch (e, stack) {
      _isConnecting = false;
      _log('❌ Connection failed: $e');
      _log('❌ Stack: $stack');
      _handleConnectionError();
      rethrow;
    }
  }

  Future<void> resumeIfNeeded() async {
    if (_intentionallyStopped) return;

    final caseId = _currentCaseId;
    if (caseId == null) return;

    _log('🔄 [Resume] Checking connection state...');
    _log(
      '🔄 [Resume] isConnected: $_isConnected, isConnecting: $_isConnecting',
    );
    _log('🔄 [Resume] wasDisconnectedBySystem: $_wasDisconnectedBySystem');

    if (!_isConnected && !_isConnecting) {
      _log('🔄 [Resume] Reconnecting after resume...');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      await _cleanupConnection(keepRecorder: true);
      _isConnecting = false;
      await connect(caseId: caseId);
    } else if (_wasDisconnectedBySystem) {
      _log('🔄 [Resume] System disconnection detected - refreshing connection');
      _wasDisconnectedBySystem = false;
      _reconnectAttempts = 0;
      await _cleanupConnection(keepRecorder: true);
      await Future.delayed(const Duration(milliseconds: 500));
      _isConnecting = false;
      await connect(caseId: caseId);
    } else {
      _log('✅ [Resume] Already connected — no action needed');
    }
  }

  Future<void> stop() async {
    _log('🛑 Stopping audio stream...');
    _intentionallyStopped = true;

    _cancelTimers();
    _disposeConnectivityListener();
    _cancelInterruptionListener();

    await _cleanupConnection(keepRecorder: false);
    await _disposeRecorder();

    _currentCaseId = null;
    _log('✅ Audio stream stopped completely');
  }

  Future<void> dispose() async {
    await stop();
  }

  // --------------------------------------------------------------
  // PRIVATE HELPERS
  // --------------------------------------------------------------
  void _sendJoinMessage(String caseId) {
    try {
      final message = jsonEncode({
        'type': 'join',
        'caseId': caseId,
        'isSender': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _channel?.sink.add(message);
      _log('✅ Join message sent');
    } catch (e) {
      _log('❌ Failed to send join message: $e');
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_intentionallyStopped) return;
      if (_isConnected && _currentCaseId != null) {
        try {
          _channel?.sink.add(
            jsonEncode({
              'type': 'ping',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          );
        } catch (e) {
          _log('⚠️ Health check ping failed: $e');
          _handleConnectionError();
        }
      }
    });
  }

  void _startConnectionWatchdog() {
    _connectionWatchdogTimer?.cancel();
    _connectionWatchdogTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_intentionallyStopped) return;
      if (_isConnected && _chunkCount > 0) {
        _log('🐕 [Watchdog] Connection active, chunks sent: $_chunkCount');
      }
    });
  }

  void _handleConnectionError() {
    if (_intentionallyStopped) return;
    _isConnected = false;
    _wasDisconnectedBySystem = true;

    if (_waitingForNetwork) {
      _log('📶 Waiting for network, not scheduling retry timer');
      return;
    }

    if (_reconnectAttempts < _maxReconnectAttempts && _currentCaseId != null) {
      _reconnectAttempts++;
      final delaySecs = (_reconnectAttempts * 2).clamp(2, 20);
      _log(
        '🔄 Reconnecting in ${delaySecs}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...',
      );

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
        _attemptReconnect();
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('❌ Max reconnection attempts reached. Streaming stopped.');
      _isRecording = false;
      _disposeRecorder();
    }
  }

  Future<void> _attemptReconnect() async {
    if (_intentionallyStopped || _currentCaseId == null) return;
    _log('🔄 Attempting reconnect...');
    try {
      await _cleanupConnection(keepRecorder: true);
      _isConnecting = false;
      await connect(caseId: _currentCaseId!);
    } catch (e) {
      _log('❌ Reconnection failed: $e');
      _handleConnectionError();
    }
  }

  void _listenToMessages() {
    _log('👂 Starting to listen for WebSocket messages...');

    _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          final type = data['type'] as String?;
          _log('📨 Message type: $type');

          switch (type) {
            case 'joined':
              _log('✅ Joined case: ${data['caseId']}');
              _ensureRecordingActive();
              break;
            case 'pong':
              _log('🏓 Received pong from server');
              break;
            case 'listener_update':
              _log('👥 Listener update: count=${data['count']}');
              break;
            case 'sender_left':
              _log('⚠️ Sender left notification received');
              break;
            default:
              _log('📨 Unknown message type: $type');
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
          _wasDisconnectedBySystem = true;
          _handleConnectionError();
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _ensureRecordingActive() async {
    if (_recorder == null || !await _recorder!.isRecording()) {
      _log('🎬 Recorder not active — restarting recording...');
      _isRecording = false;
      await _restartRecording();
    } else {
      _log('🎙️ Recorder already active');
    }
  }

  Future<void> _restartRecording() async {
    _log('🔄 Restarting recording pipeline...');
    try {
      if (_recorder != null) {
        if (await _recorder!.isRecording()) {
          await _recorder!.stop();
        }
        await _recorder!.dispose();
        _recorder = null;
      }
    } catch (e) {
      _log('⚠️ Error disposing old recorder: $e');
    }
    await _audioStreamSub?.cancel();
    _isRecording = false;
    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (_recorder != null && await _recorder!.isRecording()) {
      _log('⚠️ Recorder already active, skipping start');
      _isRecording = true;
      return;
    }

    if (_recorder != null) {
      await _recorder!.dispose();
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
    _log('   - Sample Rate: $_sampleRate Hz');
    _log('   - Bit Rate: $_bitRate');
    _log('   - Channels: $_numChannels (Mono)');

    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        bitRate: _bitRate,
        sampleRate: _sampleRate,
        numChannels: _numChannels,
      ),
    );

    _isRecording = true;
    _chunkCount = 0;
    _totalBytesSent = 0;

    _cancelInterruptionListener();
    final session = await AudioSession.instance;
    _interruptionSub = session.interruptionEventStream.listen(
      _handleInterruption,
    );

    _log('✅ Recording started successfully!');

    _audioStreamSub = stream.listen(
      (data) {
        if (_isConnected && _channel != null) {
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
                'caseId': _currentCaseId,
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
        _log('📊 Final stats: chunks: $_chunkCount, bytes: $_totalBytesSent');
      },
    );
  }

  void _handleInterruption(AudioInterruptionEvent event) {
    _log('🔇 Audio interruption: begin=${event.begin}, type=${event.type}');
    if (event.begin) {
      _isConnected = false;
      _log('⏸️ Audio interrupted – pausing stream');
    } else {
      _log('▶️ Audio interruption ended – resuming stream');
      _isConnected = false;
      _wasDisconnectedBySystem = true;
      resumeIfNeeded();
    }
  }

  // --------------------------------------------------------------
  // 🔧 FIXED: _cleanupConnection no longer hangs on sink.close()
  // --------------------------------------------------------------
  Future<void> _cleanupConnection({bool keepRecorder = false}) async {
    _log('🧹 [Cleanup] Cleaning up connection...');

    if (!keepRecorder) {
      try {
        if (_recorder != null && await _recorder!.isRecording()) {
          await _recorder!.stop();
          _log('✅ Recorder stopped');
        }
      } catch (e) {
        _log('⚠️ Error stopping recorder: $e');
      }
    }

    try {
      await _audioStreamSub?.cancel();
      _log('✅ Audio stream subscription cancelled');
    } catch (e) {
      _log('⚠️ Error cancelling subscription: $e');
    }

    // Send leave message only if we believe we are still connected
    if (_channel != null && _currentCaseId != null && _isConnected) {
      try {
        _log('📤 Sending leave message...');
        _channel!.sink.add(
          jsonEncode({'type': 'leave', 'caseId': _currentCaseId}),
        );
        _log('✅ Leave message sent');
      } catch (e) {
        _log('⚠️ Error sending leave message: $e');
      }
    }

    // ✅ Close the WebSocket without waiting indefinitely
    if (_channel != null) {
      try {
        _log('🔌 Closing WebSocket connection...');
        // Fire-and-forget: just initiate the close and move on
        _channel!.sink.close().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () {
            _log('⚠️ WebSocket close timed out – continuing anyway');
          },
        );
        // Immediately discard the reference to avoid any further usage
        _channel = null;
        _log('✅ WebSocket close initiated');
      } catch (e) {
        _log('⚠️ WebSocket close error (ignored): $e');
        _channel = null;
      }
    }

    _isConnected = false;
    _isConnecting = false;
    if (!keepRecorder) {
      _isRecording = false;
    }
    _log('✅ Connection cleanup complete');
  }

  Future<void> _disposeRecorder() async {
    try {
      await _recorder?.dispose();
      _recorder = null;
      _log('✅ Recorder disposed');
    } catch (e) {
      _log('⚠️ Error disposing recorder: $e');
    }
    _cancelInterruptionListener();
  }

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _connectionWatchdogTimer?.cancel();
    _connectionWatchdogTimer = null;
  }

  void _cancelInterruptionListener() {
    _interruptionSub?.cancel();
    _interruptionSub = null;
  }

  // ---------- connectivity handling ----------
  void _startConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final online =
          results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      _handleConnectivityChange(online);
    });
  }

  void _disposeConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  void _handleConnectivityChange(bool online) {
    _log('📶 Connectivity changed: ${online ? "online" : "offline"}');

    if (_intentionallyStopped || _currentCaseId == null) return;

    if (!online) {
      _waitingForNetwork = true;
      _reconnectTimer?.cancel();
      _log('🔴 Network offline – pausing reconnection attempts');
    } else {
      _log('🟢 Network online – starting reconnection');
      _waitingForNetwork = false;
      if (!_isConnected && !_isConnecting) {
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        _handleConnectionError();
      }
    }
  }
}
