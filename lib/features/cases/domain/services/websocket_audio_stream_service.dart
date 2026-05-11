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
  StreamSubscription? _wsMessageSub;
  AudioRecorder? _recorder;

  StreamSubscription<Uint8List>? _recorderPipeSub;
  StreamSubscription<Uint8List>? _audioStreamSub;

  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  Timer? _connectionWatchdogTimer;
  bool _wasInterrupted = false;
  bool _waitingForChunkAck = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _waitingForNetwork = false;

  DateTime? _lastPongTime;
  static const Duration _pingInterval = Duration(seconds: 10);
  static const Duration _pongTimeout = Duration(seconds: 35);

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
      'wss://skudyx-backend-thtu.onrender.com/ws/audio-stream';

  static const int _sampleRate = 44100;
  static const int _bitRate = 128000;
  static const int _numChannels = 1;

  StreamController<Uint8List>? _audioController;

  void _log(String msg) {
    if (kDebugMode) print('🎙️ [WebSocket] $msg');
  }

  bool get isStreaming => _isRecording && _isConnected;
  String? get currentCaseId => _currentCaseId;
  int get chunkCount => _chunkCount;
  int get totalBytesSent => _totalBytesSent;
  bool get isConnected => _isConnected;
  DateTime? _lastChunkSentTime;

  // ─────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────

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
      _log('🔌 Connecting to WebSocket...');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      await _channel!.ready.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw TimeoutException('WebSocket connection timeout'),
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _waitingForNetwork = false;
      _lastPongTime = DateTime.now();

      _log('✅ WebSocket connected!');

      _sendJoinMessage(caseId);
      _listenToMessages();
      _startHealthCheck();
      _startConnectionWatchdog();

      await _fullRestartRecordingPipeline();
    } catch (e, stack) {
      _isConnecting = false;
      _log('❌ Connection failed: $e\n$stack');
      _handleConnectionError();
      rethrow;
    }
  }

  Future<void> resumeIfNeeded() async {
    if (_intentionallyStopped) return;
    final caseId = _currentCaseId;
    if (caseId == null) return;

    _log('🔄 [Resume] isConnected=$_isConnected isConnecting=$_isConnecting');

    if (!_isConnected && !_isConnecting) {
      _log('🔄 [Resume] Reconnecting...');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      await _cleanupConnection(keepRecorder: false);
      _isConnecting = false;
      await connect(caseId: caseId);
    } else if (_wasDisconnectedBySystem) {
      _log('🔄 [Resume] System disconnection — refreshing');
      _wasDisconnectedBySystem = false;
      _reconnectAttempts = 0;
      await _cleanupConnection(keepRecorder: false);
      await Future.delayed(const Duration(milliseconds: 500));
      _isConnecting = false;
      await connect(caseId: caseId);
    } else if (_isConnected && !_isRecording) {
      _log('🔄 [Resume] Connected but recorder dead — restarting pipeline');
      await _fullRestartRecordingPipeline();
    }
  }

  Future<void> stop() async {
    _log('🛑 Stopping audio stream...');
    _intentionallyStopped = true;

    _cancelTimers();
    _disposeConnectivityListener();
    _cancelInterruptionListener();

    await _audioStreamSub?.cancel();
    _audioStreamSub = null;

    await _recorderPipeSub?.cancel();
    _recorderPipeSub = null;

    await _cleanupConnection(keepRecorder: false);
    await _disposeRecorder();

    _audioController?.close();
    _audioController = null;
    _wasInterrupted = false;
    _waitingForChunkAck = false;
    _ackCompleter?.complete(false);
    _ackCompleter = null;

    _currentCaseId = null;
    _log('✅ Audio stream stopped completely');
  }

  Future<void> dispose() async => stop();

  // ─────────────────────────────────────────────────
  // RECORDING PIPELINE
  // ─────────────────────────────────────────────────

  Future<void> _fullRestartRecordingPipeline() async {
    _log('🔄 [Pipeline] Full restart of recording pipeline...');

    await _audioStreamSub?.cancel();
    _audioStreamSub = null;
    await _recorderPipeSub?.cancel();
    _recorderPipeSub = null;

    try {
      if (_recorder != null) {
        if (await _recorder!.isRecording()) await _recorder!.stop();
        await _recorder!.dispose();
      }
    } catch (e) {
      _log('⚠️ [Pipeline] Recorder teardown error (ignored): $e');
    }
    _recorder = null;
    _isRecording = false;

    _audioController?.close();
    _audioController = StreamController<Uint8List>.broadcast();

    await _startPersistentRecording();

    _attachSender();

    _log('✅ [Pipeline] Recording pipeline restarted');
  }

  Future<void> _startPersistentRecording() async {
    if (_isRecording) return;

    _log('🎤 Starting persistent recorder...');
    _recorder = AudioRecorder();

    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      _log('❌ Microphone permission denied!');
      throw Exception('Microphone permission denied');
    }

    final session = await AudioSession.instance;
    await session.setActive(true);

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
    _interruptionSub = session.interruptionEventStream.listen(
      _handleInterruption,
    );

    _recorderPipeSub = stream.listen(
      (data) {
        // Show raw PCM sample for the first few chunks
        if (_chunkCount < 3) {
          final hex = data
              .take(16)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(' ');
          _log('🎙️ RAW SAMPLE (first 16 bytes): $hex');
        }
        if (!(_audioController?.isClosed ?? true)) {
          _audioController!.add(data);
        }
      },
      onError: (error) {
        _log('❌ Audio stream error: $error');
        _isRecording = false;
        if (!_intentionallyStopped) {
          Future.delayed(const Duration(seconds: 1), () {
            if (!_intentionallyStopped && _isConnected) {
              _fullRestartRecordingPipeline();
            }
          });
        }
      },
      onDone: () {
        _log('🏁 Recorder stream done — marking for restart');
        _isRecording = false;
        if (!_intentionallyStopped && _isConnected) {
          Future.delayed(const Duration(seconds: 1), () {
            if (!_intentionallyStopped && _isConnected) {
              _log('🔄 Recorder killed by OS — restarting pipeline');
              _fullRestartRecordingPipeline();
            }
          });
        }
      },
      cancelOnError: false,
    );

    _log('✅ Persistent recording active');
  }

  void _attachSender() {
    _audioStreamSub?.cancel();
    _audioStreamSub = _audioController?.stream.listen((data) {
      // Only send if WebSocket is connected (audio interruption does NOT affect connection)
      if (_isConnected && _channel != null) {
        _chunkCount++;
        _totalBytesSent += data.length;
        _lastChunkSentTime = DateTime.now();

        final chunkBase64 = base64Encode(data);
        if (_chunkCount <= 3) {
          _log('📦 Base64 chunk length: ${chunkBase64.length}');
          _log('📤 Sending chunk preview: ${chunkBase64.substring(0, 40)}...');
        }

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
            _log('📤 Chunk #$_chunkCount (${data.length}B)');
          }
        } catch (e) {
          _log('❌ Failed to send chunk: $e');
        }
      }
    });
  }

  // ✅ FIXED: Do not set _isConnected = false on interruption begin.
  // Only restart the recording pipeline when interruption ends.
  void _handleInterruption(AudioInterruptionEvent event) {
    _log('🔇 Audio interruption: begin=${event.begin} type=${event.type}');
    if (event.begin) {
      _wasInterrupted = true;
      // Audio session was interrupted – the recorder will stop automatically.
      // Do NOT change WebSocket connection state.
    } else {
      if (!_wasInterrupted) return;
      _wasInterrupted = false;
      _log('▶️ Interruption ended — recovering...');
      if (!_intentionallyStopped && _currentCaseId != null) {
        _recoverAfterInterruption();
      }
    }
  }

  Future<void> _recoverAfterInterruption() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_intentionallyStopped) return;

    _log('🔍 Probing WS with ping...');
    _waitingForChunkAck = true;

    bool probeSent = false;
    try {
      _channel?.sink.add(
        jsonEncode({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      probeSent = true;
      _log('📤 Probe ping sent — waiting for pong...');
    } catch (e) {
      _log('❌ Probe send failed — WS is dead: $e');
      _waitingForChunkAck = false;
      await _doFullReconnect();
      return;
    }

    if (!probeSent) {
      return;
    }

    final ackReceived = await _waitForServerAck(
      timeout: const Duration(seconds: 5),
    );

    _waitingForChunkAck = false;

    if (ackReceived) {
      _log('✅ Pong received — WS alive, restarting recorder only');
      await _fullRestartRecordingPipeline();
    } else {
      _log('❌ No pong — WS dead, doing full reconnect');
      await _doFullReconnect();
    }
  }

  Completer<bool>? _ackCompleter;

  Future<bool> _waitForServerAck({required Duration timeout}) async {
    _ackCompleter = Completer<bool>();

    final timer = Timer(timeout, () {
      if (!(_ackCompleter?.isCompleted ?? true)) {
        _ackCompleter?.complete(false); // timed out = WS dead
      }
    });

    final result = await _ackCompleter!.future;
    timer.cancel();
    _ackCompleter = null;
    return result;
  }

  Future<void> _doFullReconnect() async {
    if (_intentionallyStopped || _isConnecting || _isConnected) return;
    _log('🔄 Full reconnect triggered');
    _isConnected = false;
    _reconnectAttempts = 0;
    _reconnectTimer
        ?.cancel(); // ✅ cancel any pending _handleConnectionError timer
    await _cleanupConnection(keepRecorder: false);
    await Future.delayed(const Duration(milliseconds: 300));
    _isConnecting = false;
    await connect(caseId: _currentCaseId!);
  }

  // ─────────────────────────────────────────────────
  // CONNECTION HELPERS
  // ─────────────────────────────────────────────────

  void _sendJoinMessage(String caseId) {
    try {
      _channel?.sink.add(
        jsonEncode({
          'type': 'join',
          'caseId': caseId,
          'isSender': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      _log('✅ Join message sent');
    } catch (e) {
      _log('❌ Failed to send join: $e');
    }
  }

  void _listenToMessages() {
    _wsMessageSub?.cancel();
    _wsMessageSub = _channel!.stream.listen(
      (message) {
        if (_waitingForChunkAck && !(_ackCompleter?.isCompleted ?? true)) {
          _log('✅ Server responded during probe');
          _ackCompleter?.complete(true);
        }
        try {
          final data = jsonDecode(message);
          final type = data['type'] as String?;
          switch (type) {
            case 'no_chunk':
              _log('⚠️ Server says no_chunk');
              // If we're probing, ack already completed above.
              // If this fires during normal streaming = real error.
              if (!_waitingForChunkAck) {
                _handleConnectionError();
              }
              break;
            case 'joined':
              _log('✅ Joined case: ${data['caseId']}');
              break;
            case 'pong':
              _lastPongTime = DateTime.now();
              if (_waitingForChunkAck &&
                  !(_ackCompleter?.isCompleted ?? true)) {
                _ackCompleter?.complete(true);
              }
              break;
            case 'listener_update':
              _log('👥 Listeners: ${data['count']}');
              break;
            default:
              _log('📨 Unknown type: $type');
          }
        } catch (e) {
          _log('❌ Message parse error: $e');
        }
      },
      onError: (error) {
        _log('❌ WS error: $error');
        _isConnected = false;
        if (!(_ackCompleter?.isCompleted ?? true)) {
          _ackCompleter?.complete(false);
        }
        if (!_intentionallyStopped) _handleConnectionError();
      },
      onDone: () {
        _log('🔌 WS closed');
        _isConnected = false;
        if (!_intentionallyStopped && _currentCaseId != null) {
          _wasDisconnectedBySystem = true;
          _handleConnectionError();
        }
      },
      cancelOnError: false,
    );
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_pingInterval, (_) {
      if (_intentionallyStopped || !_isConnected) return;
      // ✅ Pong timeout — but only if we haven't heard from server recently
      if (_lastPongTime != null &&
          DateTime.now().difference(_lastPongTime!) > _pongTimeout) {
        _log('⚠️ Pong timeout — WS silently dead, reconnecting');
        _handleConnectionError();
        return;
      }

      // ✅ Skip ping if audio is actively flowing (chunks are the heartbeat)
      final recentlySentChunk =
          _lastChunkSentTime != null &&
          DateTime.now().difference(_lastChunkSentTime!) <
              const Duration(seconds: 8);

      if (recentlySentChunk) {
        _log('💓 Heartbeat skipped — audio stream active');
        return;
      }
      try {
        _channel?.sink.add(
          jsonEncode({
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        );
      } catch (e) {
        _handleConnectionError();
      }
    });
  }

  void _startConnectionWatchdog() {
    _connectionWatchdogTimer?.cancel();
    _connectionWatchdogTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_intentionallyStopped) return;
      if (_isConnected && !_isRecording) {
        _log('🐕 [Watchdog] Connected but recorder dead — restarting pipeline');
        _fullRestartRecordingPipeline();
      } else if (_isConnected && _isRecording) {
        _log('🐕 [Watchdog] OK — chunks=$_chunkCount');
      }
    });
  }

  void _handleConnectionError() {
    if (_intentionallyStopped) return;
    _isConnected = false;
    _wasDisconnectedBySystem = true;

    if (_waitingForNetwork) {
      _log('📶 Waiting for network...');
      return;
    }

    if (_reconnectAttempts < _maxReconnectAttempts && _currentCaseId != null) {
      _reconnectAttempts++;
      final delaySecs = (_reconnectAttempts * 2).clamp(2, 20);
      _log(
        '🔄 Reconnect in ${delaySecs}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
      );
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delaySecs), _attemptReconnect);
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('❌ Max reconnect attempts reached');
    }
  }

  Future<void> _attemptReconnect() async {
    if (_intentionallyStopped || _currentCaseId == null) return;
    _log('🔄 Attempting reconnect...');
    try {
      await _cleanupConnection(keepRecorder: false);
      _isConnecting = false;
      await connect(caseId: _currentCaseId!);
    } catch (e) {
      _log('❌ Reconnect failed: $e');
      _handleConnectionError();
    }
  }

  Future<void> _cleanupConnection({bool keepRecorder = false}) async {
    _log('🧹 Cleaning up connection... keepRecorder=$keepRecorder');

    await _wsMessageSub?.cancel();
    _wsMessageSub = null;

    await _audioStreamSub?.cancel();
    _audioStreamSub = null;

    if (!keepRecorder) {
      await _recorderPipeSub?.cancel();
      _recorderPipeSub = null;
    }

    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(
          jsonEncode({'type': 'leave', 'caseId': _currentCaseId}),
        );
      } catch (_) {}
    }

    try {
      _channel?.sink.close().timeout(
        const Duration(milliseconds: 800),
        onTimeout: () {},
      );
    } catch (_) {}
    _channel = null;

    _isConnected = false;
    _isConnecting = false;
    if (!keepRecorder) _isRecording = false;
  }

  Future<void> _disposeRecorder() async {
    try {
      await _recorderPipeSub?.cancel();
      _recorderPipeSub = null;
      if (_recorder != null) {
        if (await _recorder!.isRecording()) await _recorder!.stop();
        await _recorder!.dispose();
        _recorder = null;
      }
      _isRecording = false;
    } catch (e) {
      _log('⚠️ Dispose recorder error: $e');
    }
    _cancelInterruptionListener();
  }

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    _connectionWatchdogTimer?.cancel();
    _reconnectTimer = _healthCheckTimer = _connectionWatchdogTimer = null;
  }

  void _cancelInterruptionListener() {
    _interruptionSub?.cancel();
    _interruptionSub = null;
  }

  void _startConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) => _handleConnectivityChange(
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none),
      ),
    );
  }

  void _disposeConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  void _handleConnectivityChange(bool online) {
    _log('📶 Network: ${online ? "online" : "offline"}');
    if (_intentionallyStopped || _currentCaseId == null) return;

    if (!online) {
      _waitingForNetwork = true;
      _reconnectTimer?.cancel();
    } else {
      _waitingForNetwork = false;
      if (!_isConnected && !_isConnecting) {
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isConnected && !_isConnecting && !_intentionallyStopped) {
            _attemptReconnect();
          }
        });
      }
    }
  }
}
