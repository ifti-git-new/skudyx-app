import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/features/delivery/data/remote/device_delivery_api.dart';

class FoundDevice {
  final String name;
  final String timeText;
  const FoundDevice({required this.name, required this.timeText});
}

class DeviceScanController extends ChangeNotifier {
  final DeviceDeliveryApi api;
  DeviceScanController({required this.api});
  bool scanning = false;
  final List<FoundDevice> devices = [];
  bool isConnecting = false;
  String? errorMessage;
  Timer? _timer;

  void startMockScan() {
    scanning = true;
    devices.clear();
    notifyListeners();

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      devices.addAll(const [
        FoundDevice(name: 'Device 1', timeText: 'Today, 2:44 PM'),
        FoundDevice(name: 'Device 2', timeText: 'Today, 2:44 PM'),
        FoundDevice(name: 'Device 3', timeText: 'Today, 2:44 PM'),
        FoundDevice(name: 'Device 4', timeText: 'Today, 2:44 PM'),
        FoundDevice(name: 'Device 5', timeText: 'Today, 2:44 PM'),
        FoundDevice(name: 'Device 6', timeText: 'Today, 2:44 PM'),
        FoundDevice(name: 'Device 7', timeText: 'Today, 2:44 PM'),
      ]);
      scanning = false;
      notifyListeners();
    });
  }
String? connectingDeviceName;  
Future<bool> selectDevice(FoundDevice device) async {
  if (connectingDeviceName != null) return false;

  connectingDeviceName = device.name;
  errorMessage = null;
  notifyListeners();

  try {
    final randomId = _generateRandomId();
    await api.updateBleDeviceId(bleDeviceId: randomId);

    connectingDeviceName = null;
    notifyListeners();
    return true;
  } on DioException catch (e) {
    final body = e.response?.data;
    errorMessage = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : (e.message ?? 'Failed to connect device');

    connectingDeviceName = null;
    notifyListeners();
    return false;
  } catch (_) {
    errorMessage = 'Something went wrong. Please try again.';
    connectingDeviceName = null;
    notifyListeners();
    return false;
  }
}

  /// ✅ Random string generator
  String _generateRandomId({int length = 12}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rand.nextInt(chars.length)),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
