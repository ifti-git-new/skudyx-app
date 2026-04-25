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

  final _controller = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get stream => _controller.stream;

  // Stream for status updates broadcast from web dashboard
  final _statusUpdateController = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get statusUpdateStream =>
      _statusUpdateController.stream;

  final _log = (String msg) {
    if (kDebugMode) print('📡 [CaseRealtime] $msg');
  };

  Future<void> connect({required String userId}) async {
    if (_isConnected) return;

    _socket = io.io(
      'https://skudyx-backend-c8do.onrender.com', // ✅ Use your actual backend URL
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

    // Listen for general case updates (from any source)
    _socket!.on('case_updated', (data) {
      _log('📥 Received case update: ${data['status'] ?? data['new_status']}');
      final event = _parseCaseUpdateEvent(data);
      if (event != null) _controller.add(event);
    });

    // ✅ Listen for status updates broadcast from web dashboard
    _socket!.on('case_status_updated', (data) {
      _log(
        '📥 Received status update from web: ${data['new_status'] ?? data['status']}',
      );
      _log('📥 Raw data: $data');

      final event = _parseCaseUpdateEvent(data);
      if (event != null) {
        _statusUpdateController.add(event);
      } else {
        _log('❌ Failed to parse case_status_updated event');
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _log('🔌 Socket.IO disconnected');
    });

    _socket!.onError((error) {
      _log('❌ Socket.IO error: $error');
    });
  }

  // ✅ Helper: Parse event with flexible field names
  CaseUpdateEvent? _parseCaseUpdateEvent(Map<String, dynamic> data) {
    try {
      final caseId = data['case_id']?.toString();
      if (caseId == null || caseId.isEmpty) return null;

      // Accept both 'status' and 'new_status' field names
      final status = (data['status'] ?? data['new_status'])?.toString();
      if (status == null || status.isEmpty) return null;

      final note = data['note']?.toString();
      final updatedBy = data['updated_by']?.toString();

      // Parse updated_at with fallback
      DateTime updatedAt;
      try {
        final updatedAtStr = data['updated_at']?.toString();
        updatedAt = updatedAtStr != null && updatedAtStr.isNotEmpty
            ? DateTime.parse(updatedAtStr)
            : DateTime.now();
      } catch (_) {
        updatedAt = DateTime.now();
      }

      return CaseUpdateEvent(
        caseId: caseId,
        status: status,
        note: note,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
      );
    } catch (e) {
      _log('❌ Error parsing CaseUpdateEvent: $e');
      return null;
    }
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

  void dispose() {
    _controller.close();
    _statusUpdateController.close();
    _socket?.disconnect();
    _socket?.dispose();
  }
}
