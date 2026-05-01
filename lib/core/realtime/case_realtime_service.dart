import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';

class CaseUpdateEvent {
  final String caseId;
  final String status;
  final String? note;
  final DateTime updatedAt;
  final String? updatedBy;

  CaseUpdateEvent({
    required this.caseId,
    required this.status,
    this.note,
    required this.updatedAt,
    this.updatedBy,
  });
}

class CaseRealtimeService {
  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentCaseId;
  String? _userId;

  final _controller = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get stream => _controller.stream;

  final _statusUpdateController = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get statusUpdateStream =>
      _statusUpdateController.stream;

  final _log = (String msg) {
    if (kDebugMode) print('📡 [CaseRealtime] $msg');
  };

  static const Duration _connectTimeout = Duration(seconds: 20);
  static const int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;

  Future<void> connect({required String userId}) async {
    if (_isConnected) return;

    _userId = userId;
    _log('🔌 Connecting to Socket.IO...');

    _socket = io.io(
      'https://skudyx-backend-c8do.onrender.com',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setTimeout(_connectTimeout.inMilliseconds)
          .build(),
    );

    // ✅ Catch all dynamic events from backend
    _socket!.onAny((event, data) {
      _log('🔍 [DEBUG] Received event: "$event" => $data');

      if (event.startsWith('case_update_') && data is Map) {
        _handleCaseUpdate(_castMap(data), event);
      } else if (event == 'admin_notification' ||
          event == 'update_case_status') {
        if (data is Map && data['case_id'] != null) {
          _handleCaseUpdate(_castMap(data), event);
        }
      }
    });

    _socket!.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      _log('✅ Socket.IO connected! ID: ${_socket!.id}');

      // ✅ Join user room
      _socket!.emit('join_user_room', _userId);
      _log('📤 join_user_room emitted for: $_userId');

      // ✅ Rejoin case room if we were watching one before disconnect
      if (_currentCaseId != null) {
        _socket!.emit('join_case', _currentCaseId);
        _log('📤 Rejoined case room after reconnect: $_currentCaseId');
      }
    });

    _socket!.onConnectError((error) {
      _log('❌ Socket.IO connect error: $error');
    });

    _socket!.onError((error) {
      _log('❌ Socket.IO error: $error');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _log('🔌 Socket.IO disconnected');
      _attemptReconnect();
    });

    // ✅ Legacy fallback listeners
    _socket!.on('case_updated', (dynamic data) {
      if (data is Map) _handleCaseUpdate(_castMap(data), 'case_updated');
    });

    _socket!.on('case_status_updated', (dynamic data) {
      if (data is Map) _handleCaseUpdate(_castMap(data), 'case_status_updated');
    });

    _socket!.on('case_update', (dynamic data) {
      if (data is Map && data['case_id'] != null) {
        _handleCaseUpdate(_castMap(data), 'case_update');
      }
    });

    _socket!.connect();
  }

  Map<String, dynamic> _castMap(Map<dynamic, dynamic> raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  void _handleCaseUpdate(Map<String, dynamic> data, String eventType) {
    final caseId = (data['case_id'] ?? data['caseId'] ?? data['id'])
        ?.toString();
    final status = (data['status'] ?? data['new_status'])?.toString();
    final note = data['note']?.toString();
    final updatedAtStr = data['updated_at'] ?? data['timestamp'];
    final updatedBy = data['updated_by']?.toString();

    if (caseId == null || status == null) {
      _log('⚠️ Invalid case update data: $data');
      return;
    }

    final updatedAt = updatedAtStr != null
        ? (updatedAtStr is String ? DateTime.tryParse(updatedAtStr) : null) ??
              DateTime.now()
        : DateTime.now();

    _log('📥 $eventType: $caseId => $status (by: $updatedBy)');

    final event = CaseUpdateEvent(
      caseId: caseId,
      status: status,
      note: note,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );

    // ✅ Always emit to main stream
    _controller.add(event);

    // ✅ Also emit to status stream for status-specific events
    if (eventType.contains('status')) {
      _statusUpdateController.add(event);
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('❌ Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _log(
      '🔄 Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    Future.delayed(delay, () {
      if (_userId != null) {
        _log('🔄 Attempting reconnect...');
        connect(userId: _userId!);
      }
    });
  }

  // ✅ Fixed: single emit, no double-fire, queues join for after connect
  Future<void> watchCase(String caseId) async {
    _currentCaseId = caseId;

    if (!_isConnected) {
      // ✅ Will be joined automatically in onConnect handler above
      _log('⚠️ Not connected yet — case join queued: $caseId');
      return;
    }

    _socket!.emit('join_case', caseId);
    _log('📤 join_case emitted: $caseId');
  }

  Future<void> unwatchCase() async {
    if (_currentCaseId != null && _isConnected) {
      _socket?.emit('leave_case', _currentCaseId);
      _log('📁 Left case room: $_currentCaseId');
    }
    _currentCaseId = null;
  }

  bool get isConnected => _isConnected;
  String? get currentCaseId => _currentCaseId;

  void dispose() {
    _controller.close();
    _statusUpdateController.close();
    _socket?.disconnect();
    _socket?.dispose();
    _log('🗑️ CaseRealtimeService disposed');
  }
}
