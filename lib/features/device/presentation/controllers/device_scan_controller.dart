import 'dart:async';
import 'package:flutter/foundation.dart';

class FoundDevice {
  final String name;
  final String timeText;
  const FoundDevice({required this.name, required this.timeText});
}

class DeviceScanController extends ChangeNotifier {
  bool scanning = false;
  final List<FoundDevice> devices = [];

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
