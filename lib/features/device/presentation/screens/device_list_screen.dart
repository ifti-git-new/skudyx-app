import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

import '../controllers/device_scan_controller.dart';
import '../../../../core/navigation/app_routes.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  static const _bg = Color(0xFFF7F8FA);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Start scan once when the screen is shown
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scan = context.read<DeviceScanController>();

        // Start scan only if nothing is there yet
        if (scan.devices.isEmpty && !scan.scanning) {
          scan.startMockScan(); // later replace with real BLE scan
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<DeviceScanController>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Devices',
                    style: AppTextStyles.h2light.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Loading / empty state
            if (scan.devices.isEmpty) ...[
              Expanded(
                child: Center(
                  child: scan.scanning
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'Searching for devices...',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No devices found',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () => context
                                    .read<DeviceScanController>()
                                    .startMockScan(),
                                child: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ] else ...[
              // ✅ List view (when devices exist)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: scan.devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final d = scan.devices[i];
                    return _DeviceCard(
                      name: d.name,
                      timeText: d.timeText,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected ${d.name}')),
                        );

                        // Go to connected dashboard
                        context.push(AppRoutes.deviceConnected);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String name;
  final String timeText;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.name,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4FD3E6),
              ),
              child: const Icon(
                Icons.phone_iphone,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF7DF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Available',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
