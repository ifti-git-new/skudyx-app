import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:skudyx/core/config/app_config.dart';
import 'package:skudyx/core/storage/auth_token_storage.dart';

class CaseUpdateEvent {
  final String caseId;
  final String status;
  final String? role;
  final String? updatedBy;

  CaseUpdateEvent({
    required this.caseId,
    required this.status,
    this.role,
    this.updatedBy,
  });
}

class CaseRealtimeService {
  final AppConfig config;
  final AuthTokenStorage tokenStorage;

  CaseRealtimeService({required this.config, required this.tokenStorage});

  IO.Socket? _socket;
  String? _watchingCaseId;

  final _updates = StreamController<CaseUpdateEvent>.broadcast();
  Stream<CaseUpdateEvent> get updates => _updates.stream;

  Future<void> _ensureConnected() async {
    if (_socket != null) return;

    final token = await tokenStorage.readAccessToken();

    // NOTE:
    // For socket_io_client you usually pass https://... (not wss://...).
    // Make sure config.wsUrl is something like:
    // https://skudyx-backend-c8do.onrender.com
    final url = config.wsUrl;

    final socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableForceNew()
          .disableAutoConnect()
          // send token in multiple common ways (backend can pick one)
          .setAuth({'token': token})
          .setQuery({'token': token})
          .setExtraHeaders(
            token == null ? {} : {'Authorization': 'Bearer $token'},
          )
          .build(),
    );

    _socket = socket;

    socket.onConnect((_) {
      // Re-join room after reconnect
      final id = _watchingCaseId;
      if (id != null) {
        socket.emit('join_case', {'case_id': id});
      }
    });

    socket.onDisconnect((_) {});

    socket.onConnectError((e) {});
    socket.onError((e) {});

    socket.connect();
  }

  Future<void> watchCase(String caseId) async {
    await _ensureConnected();

    // Unwatch old case
    await unwatchCase();

    _watchingCaseId = caseId;

    // Join room (server must handle this)
    _socket?.emit('join_case', {'case_id': caseId});

    // Listen to backend event: case_update_<caseId>
    final eventName = 'case_update_$caseId';
    _socket?.on(eventName, (data) {
      if (data is Map) {
        final status = (data['status'] ?? '').toString();
        final role = data['role']?.toString();
        final updatedBy = data['updated_by']?.toString();

        if (status.isNotEmpty) {
          _updates.add(
            CaseUpdateEvent(
              caseId: caseId,
              status: status,
              role: role,
              updatedBy: updatedBy,
            ),
          );
        }
      }
    });
  }

  Future<void> unwatchCase() async {
    final old = _watchingCaseId;
    if (old == null) return;

    // Leave room (optional, but good)
    _socket?.emit('leave_case', {'case_id': old});

    // Remove event listener
    _socket?.off('case_update_$old');

    _watchingCaseId = null;
  }

  Future<void> dispose() async {
    await unwatchCase();
    _socket?.dispose();
    _socket = null;
    await _updates.close();
  }
}
