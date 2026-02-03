import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_routes.dart';
import '../controllers/device_scan_controller.dart';

class DeviceSearchingScreen extends StatefulWidget {
  const DeviceSearchingScreen({super.key});

  @override
  State<DeviceSearchingScreen> createState() => _DeviceSearchingScreenState();
}

class _DeviceSearchingScreenState extends State<DeviceSearchingScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceScanController>().startMockScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<DeviceScanController>();

    // When devices are found -> replace searching with list
    if (!_navigated && !scan.scanning && scan.devices.isNotEmpty) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace(AppRoutes.deviceList);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _RainbowRing(),
              const SizedBox(height: 22),
              const Text(
                'Searching for device...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RainbowRing extends StatelessWidget {
  const _RainbowRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFFF4D4D),
            Color(0xFFFFC107),
            Color(0xFF4ADE80),
            Color(0xFF22D3EE),
            Color(0xFF3B82F6),
            Color(0xFF8B5CF6),
            Color(0xFFFF4D4D),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Center(
            child: Icon(Icons.watch, size: 42, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
