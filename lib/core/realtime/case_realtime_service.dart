import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';

// Event class for case updates
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

  // ✅ Stream controller for general case updates
  final _controller = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get stream => _controller.stream;

  // ✅ NEW: Stream controller for status updates from web
  final _statusUpdateController = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get statusUpdateStream =>
      _statusUpdateController.stream;

  final _log = (String msg) {
    if (kDebugMode) print('📡 [CaseRealtime] $msg');
  };

  Future<void> connect({required String userId}) async {
    if (_isConnected) return;

    _socket = io.io(
      'https://skudyx-backend-thtu.onrender.com',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      _log('✅ Socket.IO connected');
      _socket!.emit('join_user_room', userId);
    });

    // Listen for general case updates
    _socket!.on('case_updated', (data) {
      _log('📥 Received case update: ${data['status']}');

      final event = CaseUpdateEvent(
        caseId: data['case_id'],
        status: data['status'],
        note: data['note'],
        updatedAt: DateTime.parse(data['updated_at']),
        updatedBy: data['updated_by'],
      );

      _controller.add(event);
    });

    // ✅ NEW: Listen for status updates from web (broadcast to all clients)
    _socket!.on('case_status_updated', (data) {
      _log('📥 Received status update from web: ${data['status']}');

      final event = CaseUpdateEvent(
        caseId: data['case_id'],
        status: data['status'],
        note: data['note'],
        updatedAt: DateTime.parse(data['updated_at']),
        updatedBy: data['updated_by'],
      );

      _statusUpdateController.add(event);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _log('🔌 Socket.IO disconnected');
    });

    _socket!.onError((error) {
      _log('❌ Socket.IO error: $error');
    });
  }

  Future<void> watchCase(String caseId) async {
    _currentCaseId = caseId;
    _socket?.emit('join_case', caseId);
    _log('📁 Joined case room: $caseId');
  }

  Future<void> unwatchCase() async {
    if (_currentCaseId != null) {
      _socket?.emit('leave_case', _currentCaseId);
      _log('📁 Left case room: $_currentCaseId');
    }
  }

  // ✅ NEW: Emit status update event (for symmetry, if needed from mobile)
  void emitStatusUpdate({
    required String caseId,
    required String status,
    String? note,
  }) {
    _socket?.emit('update_case_status', {
      'case_id': caseId,
      'status': status,
      'note': note,
    });
    _log('📤 Emitted status update: $status');
  }

  void dispose() {
    _controller.close();
    _statusUpdateController.close();
    _socket?.disconnect();
    _socket?.dispose();
  }
}
