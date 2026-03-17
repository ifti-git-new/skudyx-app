import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:skudyx/core/config/app_config.dart';
import 'package:skudyx/core/storage/auth_token_storage.dart';

class CaseUpdateEvent {
  final String caseId;
  final String status;
  final String? updatedBy;
  final String? role;

  CaseUpdateEvent({
    required this.caseId,
    required this.status,
    this.updatedBy,
    this.role,
  });
}

class CaseRealtimeService {
  final AppConfig config;
  final AuthTokenStorage tokenStorage;

  CaseRealtimeService({required this.config, required this.tokenStorage});

  IO.Socket? _socket;
  String? _watchingCaseId;

  final _controller = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get stream => _controller.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connectIfNeeded() async {
    if (_socket != null) return;

    final token = await tokenStorage.readAccessToken();

    // IMPORTANT:
    // For socket.io client, URL should be like https://your-domain.com
    // NOT wss://... (unless you have a dedicated websocket endpoint).
    final url = config.wsUrl;

    final socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'forceNew': true,

      // Send token in case you add socket auth later
      'auth': {'token': token},
      'query': {'token': token},
      'extraHeaders': token == null ? {} : {'Authorization': 'Bearer $token'},
    });

    _socket = socket;

    socket.onConnect((_) {
      final caseId = _watchingCaseId;
      if (caseId != null) {
        // server expects STRING
        socket.emit('join_case', caseId);
      }
    });

    socket.onDisconnect((_) {});
    socket.onConnectError((e) {});
    socket.onError((e) {});

    socket.connect();
  }

  Future<void> watchCase(String caseId) async {
    await connectIfNeeded();

    // unwatch previous case (if any)
    await unwatchCase();

    _watchingCaseId = caseId;

    // Join room: server expects a plain string
    _socket?.emit('join_case', caseId);

    // Listen for case updates
    final eventName = 'case_update_$caseId';
    _socket?.off(eventName); // prevent duplicates
    _socket?.on(eventName, (data) {
      if (data is Map) {
        final status = (data['status'] ?? '').toString();
        if (status.isEmpty) return;

        _controller.add(
          CaseUpdateEvent(
            caseId: caseId,
            status: status,
            updatedBy: data['updated_by']?.toString(),
            role: data['role']?.toString(),
          ),
        );
      }
    });
  }

  Future<void> unwatchCase() async {
    final old = _watchingCaseId;
    if (old == null) return;

    // Leave room: your backend doesn't implement leave_case currently, so skip safely
    // _socket?.emit('leave_case', old);

    _socket?.off('case_update_$old');
    _watchingCaseId = null;
  }

  Future<void> dispose() async {
    await unwatchCase();
    _socket?.dispose();
    _socket = null;
    await _controller.close();
  }
}
