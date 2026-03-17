import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skudyx/core/realtime/case_realtime_service.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';

class DeviceSessionController extends ChangeNotifier {
  final CaseApi caseApi;
  final CaseRealtimeService realtime;

  DeviceSessionController({required this.caseApi, required this.realtime}) {
    _rtSub = realtime.stream.listen(_onRealtimeUpdate);
  }

  // -------------------------
  // Device connection state
  // -------------------------
  FoundDevice? connectedDevice;
  bool get isConnected => connectedDevice != null;

  void connectDevice(FoundDevice device) {
    connectedDevice = device;
    notifyListeners();
  }

  Future<void> disconnectDevice() async {
    // ✅ Disconnect clears everything
    remotelyClosedStatus = null;
    await stopTracking(clearCase: true);
    connectedDevice = null;
    notifyListeners();
  }

  // -------------------------
  // Case tracking state
  // -------------------------
  bool starting = false;
  bool tracking = false;

  String? caseId;
  String? caseName;
  String? lastError;
  String? lastStatus;

  /// ✅ Set when admin/web closes the case so UI can auto-exit
  String? remotelyClosedStatus;

  void clearRemotelyClosedStatus() {
    remotelyClosedStatus = null;
  }

  Timer? _timer;
  bool _tickInFlight = false;

  int successUpdates = 0;
  int failedUpdates = 0;

  bool statusUpdating = false;

  final List<Map<String, dynamic>> coordinates = [];

  StreamSubscription<CaseUpdateEvent>? _rtSub;

  static const _finalStatuses = {'Resolved', 'Unresolved', 'False'};

  void _setError(String msg) {
    lastError = msg;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  Future<bool> _ensureLocationReady() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _setError('Location services are disabled.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setError('Location permission denied.');
      return false;
    }

    return true;
  }

  Future<Position> _getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<bool> startCase({
    required bool isTest,
    required String caseName,
  }) async {
    if (!isConnected) {
      _setError('No device connected.');
      return false;
    }

    if (starting || tracking) return false;

    clearError();

    final ok = await _ensureLocationReady();
    if (!ok) return false;

    starting = true;
    tracking = false;

    this.caseName = caseName;
    caseId = null;
    lastStatus = null;
    remotelyClosedStatus = null;

    successUpdates = 0;
    failedUpdates = 0;
    coordinates.clear();

    notifyListeners();

    try {
      final firstPos = await _getCurrentPosition();

      final data = await caseApi.triggerCase(
        latitude: firstPos.latitude,
        longitude: firstPos.longitude,
        isTest: isTest,
      );

      final createdCaseId = (data['case_id'] ?? '').toString();
      if (createdCaseId.isEmpty) {
        throw Exception('Missing case_id');
      }

      caseId = createdCaseId;
      lastStatus = (data['status'] ?? 'Pending').toString();

      starting = false;
      tracking = true;
      notifyListeners();

      // ✅ Start listening for admin/web status updates
      await realtime.watchCase(createdCaseId);

      await _sendOneTick();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!tracking) return;
        if (_tickInFlight) return;

        _tickInFlight = true;
        try {
          await _sendOneTick();
        } finally {
          _tickInFlight = false;
        }
      });

      return true;
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = (resp is Map && resp['message'] != null)
          ? resp['message'].toString()
          : (e.message ?? 'Failed to start case.');

      _setError(msg);

      starting = false;
      tracking = false;
      caseId = null;
      this.caseName = null;

      _timer?.cancel();
      _timer = null;

      await realtime.unwatchCase();

      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('startCase error: $e');
      }
      _setError('Failed to start case.');

      starting = false;
      tracking = false;
      caseId = null;
      this.caseName = null;

      _timer?.cancel();
      _timer = null;

      await realtime.unwatchCase();

      notifyListeners();
      return false;
    }
  }

  Future<void> _sendOneTick() async {
    final id = caseId;
    if (id == null) return;

    try {
      final pos = await _getCurrentPosition();

      coordinates.add({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await caseApi.updateLocation(
        caseId: id,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      successUpdates++;
      notifyListeners();
    } catch (_) {
      failedUpdates++;
      notifyListeners();
    }
  }

  Future<void> stopTracking({bool clearCase = false}) async {
    _timer?.cancel();
    _timer = null;
    _tickInFlight = false;

    starting = false;
    tracking = false;

    await realtime.unwatchCase();

    if (clearCase) {
      caseId = null;
      caseName = null;
      lastStatus = null;
      successUpdates = 0;
      failedUpdates = 0;
      coordinates.clear();
      lastError = null;
      // NOTE: we do NOT clear remotelyClosedStatus here (UI needs it to auto-pop)
    }

    notifyListeners();
  }

  Future<bool> updateFinalStatus({
    required String status,
    required String note,
  }) async {
    final id = caseId;
    if (id == null || id.isEmpty) {
      _setError('No active case.');
      return false;
    }

    if (statusUpdating) return false;

    clearError();
    statusUpdating = true;
    notifyListeners();

    try {
      await caseApi.updateStatus(caseId: id, status: status, note: note);

      lastStatus = status;

      // ✅ This close was initiated by the app user, not remote admin
      remotelyClosedStatus = null;

      await stopTracking(clearCase: true);

      statusUpdating = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = (resp is Map && resp['message'] != null)
          ? resp['message'].toString()
          : (e.message ?? 'Failed to update status.');

      _setError(msg);
      statusUpdating = false;
      notifyListeners();
      return false;
    } catch (_) {
      _setError('Failed to update status.');
      statusUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void _onRealtimeUpdate(CaseUpdateEvent event) async {
    final id = caseId;
    if (id == null) return;
    if (event.caseId != id) return;

    lastStatus = event.status;

    // If admin/web closes the case:
    if (_finalStatuses.contains(event.status)) {
      // ✅ Set the status for UI to auto-exit
      remotelyClosedStatus = event.status;

      // Stop + clear case locally (do not call updateFinalStatus again)
      await stopTracking(clearCase: true);
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    super.dispose();
  }
}
