// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:audio_session/audio_session.dart';
// import 'package:flutter/foundation.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:record/record.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class WebSocketAudioStreamService {
//   WebSocketChannel? _channel;
//   AudioRecorder? _recorder;
//   StreamSubscription<List<int>>? _audioStreamSub;
//   StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
//   Timer? _reconnectTimer;
//   Timer? _healthCheckTimer;
//   Timer? _connectionWatchdogTimer;

//   StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
//   bool _waitingForNetwork = false;

//   // ─── Pong tracking (detect silent disconnections) ───
//   DateTime? _lastPongTime;
//   static const Duration _pingInterval = Duration(seconds: 10);
//   static const Duration _pongTimeout = Duration(seconds: 15);

//   bool _isRecording = false;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   bool _intentionallyStopped = false;
//   bool _wasDisconnectedBySystem = false;

//   String? _currentCaseId;
//   int _chunkCount = 0;
//   int _totalBytesSent = 0;
//   int _reconnectAttempts = 0;

//   static const int _maxReconnectAttempts = 15;
//   static const String _wsUrl =
//       'wss://skudyx-backend-c8do.onrender.com/ws/audio-stream';

//   static const int _sampleRate = 44100;
//   static const int _bitRate = 128000;
//   static const int _numChannels = 1;

//   final _log = (String msg) {
//     if (kDebugMode) print('🎙️ [WebSocket Audio] $msg');
//   };

//   bool get isStreaming => _isRecording && _isConnected;
//   String? get currentCaseId => _currentCaseId;
//   int get chunkCount => _chunkCount;
//   int get totalBytesSent => _totalBytesSent;
//   bool get isConnected => _isConnected;

//   // --------------------------------------------------------------
//   // PUBLIC API
//   // --------------------------------------------------------------
//   Future<void> connect({required String caseId}) async {
//     if (_isConnecting || _isConnected) {
//       _log('⚠️ Already connecting or connected');
//       return;
//     }

//     _intentionallyStopped = false;
//     _wasDisconnectedBySystem = false;
//     _isConnecting = true;
//     _currentCaseId = caseId;

//     _startConnectivityListener();

//     try {
//       _log('🔌 Connecting to WebSocket audio stream...');
//       _log('📡 URL: $_wsUrl');
//       _log('📋 Case ID: $caseId');

//       _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

//       await _channel!.ready.timeout(
//         const Duration(seconds: 15),
//         onTimeout: () => throw TimeoutException('WebSocket connection timeout'),
//       );

//       _isConnected = true;
//       _isConnecting = false;
//       _reconnectAttempts = 0;
//       _waitingForNetwork = false;
//       _lastPongTime = DateTime.now(); // initialise right after connect

//       _log('✅ WebSocket connected successfully!');

//       _sendJoinMessage(caseId);
//       _listenToMessages();
//       _startHealthCheck();
//       _startConnectionWatchdog();

//       // Start the recording pipeline **only** after the server confirms it (in 'joined' handler).
//       // No need to call _restartRecording here – it will be triggered by the 'joined' message.
//     } catch (e, stack) {
//       _isConnecting = false;
//       _log('❌ Connection failed: $e');
//       _log('❌ Stack: $stack');
//       _handleConnectionError();
//       rethrow;
//     }
//   }

//   Future<void> resumeIfNeeded() async {
//     if (_intentionallyStopped) return;

//     final caseId = _currentCaseId;
//     if (caseId == null) return;

//     _log('🔄 [Resume] Checking connection state...');
//     _log(
//       '🔄 [Resume] isConnected: $_isConnected, isConnecting: $_isConnecting',
//     );
//     _log('🔄 [Resume] wasDisconnectedBySystem: $_wasDisconnectedBySystem');

//     if (!_isConnected && !_isConnecting) {
//       _log('🔄 [Resume] Reconnecting after resume...');
//       _reconnectAttempts = 0;
//       _reconnectTimer?.cancel();
//       await _cleanupConnection(keepRecorder: true);
//       _isConnecting = false;
//       await connect(caseId: caseId);
//     } else if (_wasDisconnectedBySystem) {
//       _log('🔄 [Resume] System disconnection detected - refreshing connection');
//       _wasDisconnectedBySystem = false;
//       _reconnectAttempts = 0;
//       await _cleanupConnection(keepRecorder: true);
//       await Future.delayed(const Duration(milliseconds: 500));
//       _isConnecting = false;
//       await connect(caseId: caseId);
//     } else {
//       _log('✅ [Resume] Already connected — no action needed');
//     }
//   }

//   Future<void> stop() async {
//     _log('🛑 Stopping audio stream...');
//     _intentionallyStopped = true;

//     _cancelTimers();
//     _disposeConnectivityListener();
//     _cancelInterruptionListener();

//     await _cleanupConnection(keepRecorder: false);
//     await _disposeRecorder();

//     _currentCaseId = null;
//     _log('✅ Audio stream stopped completely');
//   }

//   Future<void> dispose() async {
//     await stop();
//   }

//   // --------------------------------------------------------------
//   // PRIVATE HELPERS
//   // --------------------------------------------------------------
//   void _sendJoinMessage(String caseId) {
//     try {
//       final message = jsonEncode({
//         'type': 'join',
//         'caseId': caseId,
//         'isSender': true,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _channel?.sink.add(message);
//       _log('✅ Join message sent');
//     } catch (e) {
//       _log('❌ Failed to send join message: $e');
//     }
//   }

//   void _startHealthCheck() {
//     _healthCheckTimer?.cancel();
//     _healthCheckTimer = Timer.periodic(_pingInterval, (_) {
//       if (_intentionallyStopped || !_isConnected) return;

//       // Check if we missed a pong
//       if (_lastPongTime != null &&
//           DateTime.now().difference(_lastPongTime!) > _pongTimeout) {
//         _log('⚠️ Pong timeout – forcing reconnection');
//         _handleConnectionError();
//         return;
//       }

//       try {
//         _log('🏓 Sending ping');
//         _channel?.sink.add(
//           jsonEncode({
//             'type': 'ping',
//             'timestamp': DateTime.now().millisecondsSinceEpoch,
//           }),
//         );
//       } catch (e) {
//         _log('⚠️ Health check ping failed: $e');
//         _handleConnectionError();
//       }
//     });
//   }

//   void _startConnectionWatchdog() {
//     _connectionWatchdogTimer?.cancel();
//     _connectionWatchdogTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       if (_intentionallyStopped) return;
//       if (_isConnected && _chunkCount > 0) {
//         _log('🐕 [Watchdog] Connection active, chunks sent: $_chunkCount');
//       }
//     });
//   }

//   void _handleConnectionError() {
//     if (_intentionallyStopped) return;
//     _isConnected = false;
//     _wasDisconnectedBySystem = true;

//     if (_waitingForNetwork) {
//       _log('📶 Waiting for network, not scheduling retry timer');
//       return;
//     }

//     if (_reconnectAttempts < _maxReconnectAttempts && _currentCaseId != null) {
//       _reconnectAttempts++;
//       final delaySecs = (_reconnectAttempts * 2).clamp(2, 20);
//       _log(
//         '🔄 Reconnecting in ${delaySecs}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...',
//       );

//       _reconnectTimer?.cancel();
//       _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
//         _attemptReconnect();
//       });
//     } else if (_reconnectAttempts >= _maxReconnectAttempts) {
//       _log('❌ Max reconnection attempts reached. Streaming stopped.');
//       _isRecording = false;
//       _disposeRecorder();
//     }
//   }

//   Future<void> _attemptReconnect() async {
//     if (_intentionallyStopped || _currentCaseId == null) return;
//     _log('🔄 Attempting reconnect...');
//     try {
//       await _cleanupConnection(keepRecorder: true);
//       _isConnecting = false;
//       await connect(caseId: _currentCaseId!);
//     } catch (e) {
//       _log('❌ Reconnection failed: $e');
//       _handleConnectionError();
//     }
//   }

//   void _listenToMessages() {
//     _log('👂 Starting to listen for WebSocket messages...');

//     _channel!.stream.listen(
//       (message) {
//         try {
//           final data = jsonDecode(message);
//           final type = data['type'] as String?;
//           _log('📨 Message type: $type');

//           switch (type) {
//             case 'joined':
//               _log('✅ Joined case: ${data['caseId']}');
//               // Start the recording pipeline (only once, after server confirms)
//               _restartRecording();
//               break;
//             case 'pong':
//               _lastPongTime = DateTime.now();
//               _log('🏓 Received pong from server');
//               break;
//             case 'listener_update':
//               _log('👥 Listener update: count=${data['count']}');
//               break;
//             case 'sender_left':
//               _log('⚠️ Sender left notification received');
//               break;
//             default:
//               _log('📨 Unknown message type: $type');
//           }
//         } catch (e) {
//           _log('❌ Message parse error: $e');
//           _log('❌ Raw message: $message');
//         }
//       },
//       onError: (error) {
//         _log('❌ WebSocket error: $error');
//         _isConnected = false;
//         if (!_intentionallyStopped) _handleConnectionError();
//       },
//       onDone: () {
//         _log('🔌 WebSocket connection closed');
//         _isConnected = false;
//         if (!_intentionallyStopped && _currentCaseId != null) {
//           _wasDisconnectedBySystem = true;
//           _handleConnectionError();
//         }
//       },
//       cancelOnError: false,
//     );
//   }

//   Future<void> _restartRecording() async {
//     _log('🔄 Restarting recording pipeline...');
//     // Stop and dispose old recorder
//     try {
//       if (_recorder != null) {
//         if (await _recorder!.isRecording()) {
//           await _recorder!.stop();
//         }
//         await _recorder!.dispose();
//         _recorder = null;
//       }
//     } catch (e) {
//       _log('⚠️ Error disposing old recorder: $e');
//     }
//     // Cancel old audio subscription
//     await _audioStreamSub?.cancel();
//     _isRecording = false;

//     // Start a brand new recording
//     await _startRecording();
//   }

//   Future<void> _startRecording() async {
//     // Prevent duplicate recorders
//     if (_recorder != null && await _recorder!.isRecording()) {
//       _log('⚠️ Recorder already active, skipping start');
//       _isRecording = true;
//       return;
//     }

//     // Dispose zombie recorder
//     if (_recorder != null) {
//       await _recorder!.dispose();
//     }

//     _log('🎤 Initializing AudioRecorder...');
//     _recorder = AudioRecorder();

//     _log('🔐 Checking microphone permission...');
//     final hasPermission = await _recorder!.hasPermission();
//     _log('🔐 Permission status: $hasPermission');

//     if (!hasPermission) {
//       _log('❌ Microphone permission denied!');
//       throw Exception('Microphone permission denied');
//     }

//     _log('🎙️ Starting audio recording...');
//     _log('📊 Audio config:');
//     _log('   - Encoder: PCM16');
//     _log('   - Sample Rate: $_sampleRate Hz');
//     _log('   - Bit Rate: $_bitRate');
//     _log('   - Channels: $_numChannels (Mono)');

//     final stream = await _recorder!.startStream(
//       const RecordConfig(
//         encoder: AudioEncoder.pcm16bits,
//         bitRate: _bitRate,
//         sampleRate: _sampleRate,
//         numChannels: _numChannels,
//       ),
//     );

//     _isRecording = true;
//     _chunkCount = 0;
//     _totalBytesSent = 0;

//     // Listen to audio session interruptions (phone calls)
//     _cancelInterruptionListener();
//     final session = await AudioSession.instance;
//     _interruptionSub = session.interruptionEventStream.listen(
//       _handleInterruption,
//     );

//     _log('✅ Recording started successfully!');

//     _audioStreamSub = stream.listen(
//       (data) {
//         if (_isConnected && _channel != null) {
//           _chunkCount++;
//           _totalBytesSent += data.length;

//           final chunkBase64 = base64Encode(Uint8List.fromList(data));
//           try {
//             _channel!.sink.add(
//               jsonEncode({
//                 'type': 'audio_chunk',
//                 'chunk': chunkBase64,
//                 'timestamp': DateTime.now().millisecondsSinceEpoch,
//                 'chunkIndex': _chunkCount,
//                 'caseId': _currentCaseId,
//               }),
//             );

//             if (_chunkCount % 10 == 0) {
//               _log('📤 Sent chunk #$_chunkCount (${data.length} bytes)');
//               _log(
//                 '📊 Total chunks: $_chunkCount, Total bytes: $_totalBytesSent',
//               );
//             }
//           } catch (e) {
//             _log('❌ Failed to send chunk: $e');
//           }
//         }
//       },
//       onError: (error) {
//         _log('❌ Audio stream error: $error');
//       },
//       onDone: () {
//         _log('🏁 Audio stream completed');
//         _log('📊 Final stats: chunks: $_chunkCount, bytes: $_totalBytesSent');
//       },
//     );
//   }

//   void _handleInterruption(AudioInterruptionEvent event) {
//     _log('🔇 Audio interruption: begin=${event.begin}, type=${event.type}');
//     if (event.begin) {
//       _isConnected = false;
//       _log('⏸️ Audio interrupted – pausing stream');
//     } else {
//       _log('▶️ Audio interruption ended – resuming stream');
//       _isConnected = false;
//       _wasDisconnectedBySystem = true;
//       resumeIfNeeded();
//     }
//   }

//   // --------------------------------------------------------------
//   // 🔧 Safe cleanup (non‑blocking WebSocket close)
//   // --------------------------------------------------------------
//   Future<void> _cleanupConnection({bool keepRecorder = false}) async {
//     _log('🧹 [Cleanup] Cleaning up connection...');

//     if (!keepRecorder) {
//       try {
//         if (_recorder != null && await _recorder!.isRecording()) {
//           await _recorder!.stop();
//           _log('✅ Recorder stopped');
//         }
//       } catch (e) {
//         _log('⚠️ Error stopping recorder: $e');
//       }
//     }

//     try {
//       await _audioStreamSub?.cancel();
//       _log('✅ Audio stream subscription cancelled');
//     } catch (e) {
//       _log('⚠️ Error cancelling subscription: $e');
//     }

//     // Send leave message if we think we're still connected
//     if (_channel != null && _currentCaseId != null && _isConnected) {
//       try {
//         _log('📤 Sending leave message...');
//         _channel!.sink.add(
//           jsonEncode({'type': 'leave', 'caseId': _currentCaseId}),
//         );
//         _log('✅ Leave message sent');
//       } catch (e) {
//         _log('⚠️ Error sending leave message: $e');
//       }
//     }

//     // Close WebSocket without blocking – fire‑and‑forget with timeout
//     if (_channel != null) {
//       try {
//         _log('🔌 Closing WebSocket connection...');
//         _channel!.sink.close().timeout(
//           const Duration(milliseconds: 800),
//           onTimeout: () {
//             _log('⚠️ WebSocket close timed out – continuing anyway');
//           },
//         );
//         _channel = null;
//         _log('✅ WebSocket close initiated');
//       } catch (e) {
//         _log('⚠️ WebSocket close error (ignored): $e');
//         _channel = null;
//       }
//     }

//     _isConnected = false;
//     _isConnecting = false;
//     if (!keepRecorder) {
//       _isRecording = false;
//     }
//     _log('✅ Connection cleanup complete');
//   }

//   Future<void> _disposeRecorder() async {
//     try {
//       await _recorder?.dispose();
//       _recorder = null;
//       _log('✅ Recorder disposed');
//     } catch (e) {
//       _log('⚠️ Error disposing recorder: $e');
//     }
//     _cancelInterruptionListener();
//   }

//   void _cancelTimers() {
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;
//     _healthCheckTimer?.cancel();
//     _healthCheckTimer = null;
//     _connectionWatchdogTimer?.cancel();
//     _connectionWatchdogTimer = null;
//   }

//   void _cancelInterruptionListener() {
//     _interruptionSub?.cancel();
//     _interruptionSub = null;
//   }

//   // ---------- connectivity handling ----------
//   void _startConnectivityListener() {
//     _connectivitySub?.cancel();
//     _connectivitySub = Connectivity().onConnectivityChanged.listen((
//       List<ConnectivityResult> results,
//     ) {
//       final online =
//           results.isNotEmpty &&
//           results.any((r) => r != ConnectivityResult.none);
//       _handleConnectivityChange(online);
//     });
//   }

//   void _disposeConnectivityListener() {
//     _connectivitySub?.cancel();
//     _connectivitySub = null;
//   }

//   void _handleConnectivityChange(bool online) {
//     _log('📶 Connectivity changed: ${online ? "online" : "offline"}');

//     if (_intentionallyStopped || _currentCaseId == null) return;

//     if (!online) {
//       _waitingForNetwork = true;
//       _reconnectTimer?.cancel();
//       _log('🔴 Network offline – pausing reconnection attempts');
//     } else {
//       _log('🟢 Network online – starting reconnection');
//       _waitingForNetwork = false;
//       if (!_isConnected && !_isConnecting) {
//         _reconnectAttempts = 0;
//         _reconnectTimer?.cancel();
//         _handleConnectionError();
//       }
//     }
//   }
// }

// / -------------------------------------------------------------->>>>>>
// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:audio_session/audio_session.dart';
// import 'package:flutter/foundation.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:record/record.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class WebSocketAudioStreamService {
//   WebSocketChannel? _channel;
//   StreamSubscription? _wsMessageSub;
//   AudioRecorder? _recorder;

//   // Persistent controller – the recorder streams data here forever
//   final StreamController<Uint8List> _audioController =
//       StreamController<Uint8List>.broadcast();
//   StreamSubscription<Uint8List>?
//   _audioStreamSub; // subscription for sending chunks

//   StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
//   Timer? _reconnectTimer;
//   Timer? _healthCheckTimer;
//   Timer? _connectionWatchdogTimer;

//   StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
//   bool _waitingForNetwork = false;

//   DateTime? _lastPongTime;
//   static const Duration _pingInterval = Duration(seconds: 10);
//   static const Duration _pongTimeout = Duration(seconds: 15);

//   bool _isRecording = false;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   bool _intentionallyStopped = false;
//   bool _wasDisconnectedBySystem = false;

//   String? _currentCaseId;
//   int _chunkCount = 0;
//   int _totalBytesSent = 0;
//   int _reconnectAttempts = 0;

//   static const int _maxReconnectAttempts = 15;
//   static const String _wsUrl =
//       'wss://skudyx-backend-c8do.onrender.com/ws/audio-stream';

//   static const int _sampleRate = 44100;
//   static const int _bitRate = 128000;
//   static const int _numChannels = 1;

//   final _log = (String msg) {
//     if (kDebugMode) print('🎙️ [WebSocket Audio] $msg');
//   };

//   bool get isStreaming => _isRecording && _isConnected;
//   String? get currentCaseId => _currentCaseId;
//   int get chunkCount => _chunkCount;
//   int get totalBytesSent => _totalBytesSent;
//   bool get isConnected => _isConnected;

//   // --------------------------------------------------------------
//   // PUBLIC API
//   // --------------------------------------------------------------
//   Future<void> connect({required String caseId}) async {
//     if (_isConnecting || _isConnected) {
//       _log('⚠️ Already connecting or connected');
//       return;
//     }

//     _intentionallyStopped = false;
//     _wasDisconnectedBySystem = false;
//     _isConnecting = true;
//     _currentCaseId = caseId;

//     _startConnectivityListener();

//     try {
//       _log('🔌 Connecting to WebSocket audio stream...');
//       _log('📡 URL: $_wsUrl');
//       _log('📋 Case ID: $caseId');

//       _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

//       await _channel!.ready.timeout(
//         const Duration(seconds: 15),
//         onTimeout: () => throw TimeoutException('WebSocket connection timeout'),
//       );

//       _isConnected = true;
//       _isConnecting = false;
//       _reconnectAttempts = 0;
//       _waitingForNetwork = false;
//       _lastPongTime = DateTime.now();

//       _log('✅ WebSocket connected successfully!');

//       _sendJoinMessage(caseId);
//       _listenToMessages();
//       _startHealthCheck();
//       _startConnectionWatchdog();

//       // If the persistent recorder hasn't been started yet, start it now.
//       if (!_isRecording) {
//         await _startPersistentRecording();
//       }
//       // Attach/reattach the WebSocket sender to the persistent stream
//       _attachSender();
//     } catch (e, stack) {
//       _isConnecting = false;
//       _log('❌ Connection failed: $e');
//       _log('❌ Stack: $stack');
//       _handleConnectionError();
//       rethrow;
//     }
//   }

//   Future<void> resumeIfNeeded() async {
//     if (_intentionallyStopped) return;

//     final caseId = _currentCaseId;
//     if (caseId == null) return;

//     _log('🔄 [Resume] Checking connection state...');
//     _log(
//       '🔄 [Resume] isConnected: $_isConnected, isConnecting: $_isConnecting',
//     );
//     _log('🔄 [Resume] wasDisconnectedBySystem: $_wasDisconnectedBySystem');

//     if (!_isConnected && !_isConnecting) {
//       _log('🔄 [Resume] Reconnecting after resume...');
//       _reconnectAttempts = 0;
//       _reconnectTimer?.cancel();
//       await _cleanupConnection(keepRecorder: true);
//       _isConnecting = false;
//       await connect(caseId: caseId);
//     } else if (_wasDisconnectedBySystem) {
//       _log('🔄 [Resume] System disconnection detected - refreshing connection');
//       _wasDisconnectedBySystem = false;
//       _reconnectAttempts = 0;
//       await _cleanupConnection(keepRecorder: true);
//       await Future.delayed(const Duration(milliseconds: 500));
//       _isConnecting = false;
//       await connect(caseId: caseId);
//     } else {
//       _log('✅ [Resume] Already connected — no action needed');
//     }
//   }

//   Future<void> stop() async {
//     _log('🛑 Stopping audio stream...');
//     _intentionallyStopped = true;

//     _cancelTimers();
//     _disposeConnectivityListener();
//     _cancelInterruptionListener();

//     await _cleanupConnection(keepRecorder: false);
//     await _disposeRecorder();

//     _currentCaseId = null;
//     await _audioController.close();
//     _log('✅ Audio stream stopped completely');
//   }

//   Future<void> dispose() async {
//     await stop();
//   }

//   // --------------------------------------------------------------
//   // PRIVATE HELPERS
//   // --------------------------------------------------------------
//   void _sendJoinMessage(String caseId) {
//     try {
//       final message = jsonEncode({
//         'type': 'join',
//         'caseId': caseId,
//         'isSender': true,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _channel?.sink.add(message);
//       _log('✅ Join message sent');
//     } catch (e) {
//       _log('❌ Failed to send join message: $e');
//     }
//   }

//   void _startHealthCheck() {
//     _healthCheckTimer?.cancel();
//     _healthCheckTimer = Timer.periodic(_pingInterval, (_) {
//       if (_intentionallyStopped || !_isConnected) return;

//       if (_lastPongTime != null &&
//           DateTime.now().difference(_lastPongTime!) > _pongTimeout) {
//         _log('⚠️ Pong timeout – forcing reconnection');
//         _handleConnectionError();
//         return;
//       }

//       try {
//         _channel?.sink.add(
//           jsonEncode({
//             'type': 'ping',
//             'timestamp': DateTime.now().millisecondsSinceEpoch,
//           }),
//         );
//       } catch (e) {
//         _log('⚠️ Health check ping failed: $e');
//         _handleConnectionError();
//       }
//     });
//   }

//   void _startConnectionWatchdog() {
//     _connectionWatchdogTimer?.cancel();
//     _connectionWatchdogTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       if (_intentionallyStopped) return;
//       if (_isConnected && _chunkCount > 0) {
//         _log('🐕 [Watchdog] Connection active, chunks sent: $_chunkCount');
//       }
//     });
//   }

//   void _handleConnectionError() {
//     if (_intentionallyStopped) return;
//     _isConnected = false;
//     _wasDisconnectedBySystem = true;

//     if (_waitingForNetwork) {
//       _log('📶 Waiting for network, not scheduling retry timer');
//       return;
//     }

//     if (_reconnectAttempts < _maxReconnectAttempts && _currentCaseId != null) {
//       _reconnectAttempts++;
//       final delaySecs = (_reconnectAttempts * 2).clamp(2, 20);
//       _log(
//         '🔄 Reconnecting in ${delaySecs}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...',
//       );

//       _reconnectTimer?.cancel();
//       _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
//         _attemptReconnect();
//       });
//     } else if (_reconnectAttempts >= _maxReconnectAttempts) {
//       _log('❌ Max reconnection attempts reached. Streaming stopped.');
//       _isRecording = false;
//       _disposeRecorder();
//     }
//   }

//   Future<void> _attemptReconnect() async {
//     if (_intentionallyStopped || _currentCaseId == null) return;
//     _log('🔄 Attempting reconnect...');
//     try {
//       await _cleanupConnection(keepRecorder: true);
//       _isConnecting = false;
//       await connect(caseId: _currentCaseId!);
//     } catch (e) {
//       _log('❌ Reconnection failed: $e');
//       _handleConnectionError();
//     }
//   }

//   void _listenToMessages() {
//     _wsMessageSub?.cancel();
//     _wsMessageSub = _channel!.stream.listen(
//       (message) {
//         try {
//           final data = jsonDecode(message);
//           final type = data['type'] as String?;
//           _log('📨 Message type: $type');
//           _log('🎤 Microphone still active – raw data size: ${data.length}');

//           switch (type) {
//             case 'joined':
//               _log('✅ Joined case: ${data['caseId']}');
//               _attachSender(); // just re-attach sender – recorder is persistent
//               break;
//             case 'pong':
//               _lastPongTime = DateTime.now();
//               _log('🏓 Received pong from server');
//               break;
//             case 'listener_update':
//               _log('👥 Listener update: count=${data['count']}');
//               break;
//             case 'sender_left':
//               _log('⚠️ Sender left notification received');
//               break;
//             default:
//               _log('📨 Unknown message type: $type');
//           }
//         } catch (e) {
//           _log('❌ Message parse error: $e');
//           _log('❌ Raw message: $message');
//         }
//       },
//       onError: (error) {
//         _log('❌ WebSocket error: $error');
//         _isConnected = false;
//         if (!_intentionallyStopped) _handleConnectionError();
//       },
//       onDone: () {
//         _log('🔌 WebSocket connection closed');
//         _isConnected = false;
//         if (!_intentionallyStopped && _currentCaseId != null) {
//           _wasDisconnectedBySystem = true;
//           _handleConnectionError();
//         }
//       },
//       cancelOnError: false,
//     );
//   }

//   // --------------------------------------------------------------
//   // Persistent recording – the microphone is never released
//   // --------------------------------------------------------------
//   Future<void> _startPersistentRecording() async {
//     if (_isRecording) return;

//     _log('🎤 Setting up persistent audio recorder...');
//     _recorder = AudioRecorder();

//     final hasPermission = await _recorder!.hasPermission();
//     _log('🔐 Permission: $hasPermission');
//     if (!hasPermission) {
//       _log('❌ Microphone permission denied!');
//       throw Exception('Microphone permission denied');
//     }

//     final stream = await _recorder!.startStream(
//       const RecordConfig(
//         encoder: AudioEncoder.pcm16bits,
//         bitRate: _bitRate,
//         sampleRate: _sampleRate,
//         numChannels: _numChannels,
//       ),
//     );

//     _isRecording = true;
//     _chunkCount = 0;
//     _totalBytesSent = 0;

//     // Listen for audio interruptions (phone calls, etc.)
//     _cancelInterruptionListener();
//     final session = await AudioSession.instance;
//     _interruptionSub = session.interruptionEventStream.listen(
//       _handleInterruption,
//     );

//     // Pipe the recorder stream into the persistent controller
//     stream.listen(
//       (data) {
//         _audioController.add(data);
//       },
//       onError: (error) {
//         _log('❌ Audio stream error: $error');
//       },
//       onDone: () {
//         _log('🏁 Recorder stream done');
//       },
//     );

//     _log('✅ Persistent recording active');
//   }

//   /// Attaches a new sender subscription to the persistent audio stream.
//   void _attachSender() {
//     _audioStreamSub?.cancel();
//     _audioStreamSub = _audioController.stream.listen((data) {
//       if (_isConnected && _channel != null) {
//         _chunkCount++;
//         _totalBytesSent += data.length;

//         final chunkBase64 = base64Encode(data);
//         try {
//           _channel!.sink.add(
//             jsonEncode({
//               'type': 'audio_chunk',
//               'chunk': chunkBase64,
//               'timestamp': DateTime.now().millisecondsSinceEpoch,
//               'chunkIndex': _chunkCount,
//               'caseId': _currentCaseId,
//             }),
//           );

//           if (_chunkCount % 10 == 0) {
//             _log('📤 Sent chunk #$_chunkCount (${data.length} bytes)');
//             _log(
//               '📊 Total chunks: $_chunkCount, Total bytes: $_totalBytesSent',
//             );
//           }
//         } catch (e) {
//           _log('❌ Failed to send chunk: $e');
//         }
//       }
//     });
//   }

//   void _handleInterruption(AudioInterruptionEvent event) {
//     _log('🔇 Audio interruption: begin=${event.begin}, type=${event.type}');
//     if (event.begin) {
//       _isConnected = false; // stop sending chunks, but recorder stays alive
//       _log('⏸️ Audio interrupted – pausing stream');
//     } else {
//       _log('▶️ Audio interruption ended – restarting persistent recording');
//       _isConnected = false;
//       _wasDisconnectedBySystem = true;
//       _restartPersistentRecording(); // rebuild the recording pipeline
//       resumeIfNeeded(); // reconnect WebSocket
//     }
//   }

//   Future<void> _restartPersistentRecording() async {
//     _log('🔄 Restarting persistent recorder after interruption...');
//     try {
//       await _recorder?.stop();
//       await _recorder?.dispose();
//     } catch (_) {}
//     _recorder = null;
//     _isRecording = false;
//     await _startPersistentRecording();
//   }

//   Future<void> _cleanupConnection({bool keepRecorder = false}) async {
//     _log('🧹 [Cleanup] Cleaning up connection...');

//     await _wsMessageSub?.cancel();
//     _wsMessageSub = null;

//     await _audioStreamSub
//         ?.cancel(); // only cancel sender sub, not the persistent stream

//     if (!keepRecorder) {
//       try {
//         if (_recorder != null && await _recorder!.isRecording()) {
//           await _recorder!.stop();
//           _log('✅ Recorder stopped');
//         }
//       } catch (e) {
//         _log('⚠️ Error stopping recorder: $e');
//       }
//     }

//     if (_channel != null && _currentCaseId != null && _isConnected) {
//       try {
//         _log('📤 Sending leave message...');
//         _channel!.sink.add(
//           jsonEncode({'type': 'leave', 'caseId': _currentCaseId}),
//         );
//         _log('✅ Leave message sent');
//       } catch (e) {
//         _log('⚠️ Error sending leave message: $e');
//       }
//     }

//     if (_channel != null) {
//       try {
//         _log('🔌 Closing WebSocket connection...');
//         _channel!.sink.close().timeout(
//           const Duration(milliseconds: 800),
//           onTimeout: () {
//             _log('⚠️ WebSocket close timed out – continuing anyway');
//           },
//         );
//         _channel = null;
//         _log('✅ WebSocket close initiated');
//       } catch (e) {
//         _log('⚠️ WebSocket close error (ignored): $e');
//         _channel = null;
//       }
//     }

//     _isConnected = false;
//     _isConnecting = false;
//     if (!keepRecorder) {
//       _isRecording = false;
//     }
//     _log('✅ Connection cleanup complete');
//   }

//   Future<void> _disposeRecorder() async {
//     try {
//       await _recorder?.dispose();
//       _recorder = null;
//       _isRecording = false;
//       _log('✅ Recorder disposed');
//     } catch (e) {
//       _log('⚠️ Error disposing recorder: $e');
//     }
//     _cancelInterruptionListener();
//   }

//   void _cancelTimers() {
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;
//     _healthCheckTimer?.cancel();
//     _healthCheckTimer = null;
//     _connectionWatchdogTimer?.cancel();
//     _connectionWatchdogTimer = null;
//   }

//   void _cancelInterruptionListener() {
//     _interruptionSub?.cancel();
//     _interruptionSub = null;
//   }

//   // ---------- connectivity handling ----------
//   void _startConnectivityListener() {
//     _connectivitySub?.cancel();
//     _connectivitySub = Connectivity().onConnectivityChanged.listen((
//       List<ConnectivityResult> results,
//     ) {
//       final online =
//           results.isNotEmpty &&
//           results.any((r) => r != ConnectivityResult.none);
//       _handleConnectivityChange(online);
//     });
//   }

//   void _disposeConnectivityListener() {
//     _connectivitySub?.cancel();
//     _connectivitySub = null;
//   }

//   void _handleConnectivityChange(bool online) {
//     _log('📶 Connectivity changed: ${online ? "online" : "offline"}');

//     if (_intentionallyStopped || _currentCaseId == null) return;

//     if (!online) {
//       _waitingForNetwork = true;
//       _reconnectTimer?.cancel();
//       _log('🔴 Network offline – pausing reconnection attempts');
//     } else {
//       _log('🟢 Network online – starting reconnection');
//       _waitingForNetwork = false;
//       if (!_isConnected && !_isConnecting) {
//         _reconnectAttempts = 0;
//         _reconnectTimer?.cancel();
//         _handleConnectionError();
//       }
//     }
//   }
// }
//--------------------------------------------------------------->>>>>>>

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

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _waitingForNetwork = false;

  DateTime? _lastPongTime;
  static const Duration _pingInterval = Duration(seconds: 10);
  static const Duration _pongTimeout = Duration(seconds: 15);

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

  StreamController<Uint8List>? _audioController;

  void _log(String msg) {
    if (kDebugMode) print('🎙️ [WebSocket] $msg');
  }

  bool get isStreaming => _isRecording && _isConnected;
  String? get currentCaseId => _currentCaseId;
  int get chunkCount => _chunkCount;
  int get totalBytesSent => _totalBytesSent;
  bool get isConnected => _isConnected;

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
        const Duration(seconds: 15),
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
      // Audio session was interrupted – the recorder will stop automatically.
      // Do NOT change WebSocket connection state.
    } else {
      _log('▶️ Interruption ended — restarting recording pipeline');
      // Only restart the recorder, keep WebSocket alive.
      _fullRestartRecordingPipeline();
    }
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
        try {
          final data = jsonDecode(message);
          final type = data['type'] as String?;
          switch (type) {
            case 'joined':
              _log('✅ Joined case: ${data['caseId']}');
              break;
            case 'pong':
              _lastPongTime = DateTime.now();
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
      if (_lastPongTime != null &&
          DateTime.now().difference(_lastPongTime!) > _pongTimeout) {
        _log('⚠️ Pong timeout — reconnecting');
        _handleConnectionError();
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
