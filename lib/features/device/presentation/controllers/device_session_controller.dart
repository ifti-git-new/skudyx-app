import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';
import 'package:skudyx/features/device/presentation/controllers/device_scan_controller.dart';

class DeviceSessionController extends ChangeNotifier {
  final CaseApi caseApi;

  DeviceSessionController({required this.caseApi});

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
    // disconnect ends session and clears case
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

  Timer? _timer;
  bool _tickInFlight = false;

  int successUpdates = 0;
  int failedUpdates = 0;

  bool statusUpdating = false;

  String? lastError;
  String? lastStatus; // optional

  final List<Map<String, dynamic>> coordinates = [];

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

    if (permission == LocationPermission.denied) {
      _setError('Location permission denied.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _setError('Location permission permanently denied.');
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
        throw Exception('Missing case_id from backend response');
      }

      caseId = createdCaseId;
      lastStatus = (data['status'] ?? 'Pending').toString();

      starting = false;
      tracking = true;
      notifyListeners();

      // send first tick immediately
      await _sendOneTick();

      // start timer every 2 seconds
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

      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('startCase error: $e');
      }
      _setError('Something went wrong starting the case.');

      starting = false;
      tracking = false;
      caseId = null;
      this.caseName = null;

      _timer?.cancel();
      _timer = null;

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

      successUpdates += 1;
      notifyListeners();
    } catch (e) {
      failedUpdates += 1;
      notifyListeners();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Tick failed: $e');
      }
    }
  }

  Future<void> stopTracking({bool clearCase = false}) async {
    _timer?.cancel();
    _timer = null;
    _tickInFlight = false;

    starting = false;
    tracking = false;

    if (clearCase) {
      caseId = null;
      caseName = null;
      lastStatus = null;
      successUpdates = 0;
      failedUpdates = 0;
      coordinates.clear();
      lastError = null;
    }

    notifyListeners();
  }

  Future<bool> updateFinalStatus({
    required String status,
    required String note,
  }) async {
    final id = caseId;
    if (id == null || id.isEmpty) {
      _setError('No case_id found. Start a case first.');
      return false;
    }
    if (statusUpdating) return false;

    clearError();
    statusUpdating = true;
    notifyListeners();

    try {
      final data = await caseApi.updateStatus(
        caseId: id,
        status: status,
        note: note,
      );

      lastStatus = (data['status'] ?? status).toString();

      // stop tracking and CLEAR CASE (your requirement on disconnect is clear case;
      // for final statuses we usually stop tracking; keep caseId if you want.
      // If you want also clear case here, change clearCase:true.
      await stopTracking(clearCase: false);

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
      _setError('Something went wrong updating status.');
      statusUpdating = false;
      notifyListeners();
      return false;
    }
  }
}
