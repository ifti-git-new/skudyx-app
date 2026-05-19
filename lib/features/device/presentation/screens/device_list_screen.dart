import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

import '../controllers/device_scan_controller.dart';
import '../controllers/device_session_controller.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  static const _bg = Color(0xFFF7F8FA);

  bool _started = false;
  bool _redirecting = false;
  String? connectingDeviceName;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scan = context.read<DeviceScanController>();
        if (scan.devices.isEmpty && !scan.scanning) {
          scan.startMockScan();
        }
      });
    }
  }

  void _redirectToConnectedIfNeeded(DeviceSessionController session) {
    if (_redirecting) return;
    if (!session.isConnected) return;

    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoutes.deviceConnected);
      _redirecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<DeviceScanController>();
    final session = context.watch<DeviceSessionController>();

    // ✅ If this screen is opened as /device/list route and device becomes connected,
    // redirect instead of returning SizedBox.shrink() (which causes blank screen).
    _redirectToConnectedIfNeeded(session);

    // While redirecting, show a lightweight loader (avoids white blank).
    if (session.isConnected) {
      return const Scaffold(
        backgroundColor: _bg,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

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
                  const SizedBox(width: 10),
                  Text(
                    'Devices',
                    style: AppTextStyles.h2light.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (scan.devices.isEmpty) ...[
              Expanded(
                child: Center(
                  child: scan.scanning
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
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
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: scan.devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final d = scan.devices[i];
                    final isLoading = scan.connectingDeviceName == d.name;
                    return _DeviceCard(
                      name: d.name,
                      timeText: d.timeText,
                      isLoading: isLoading,
                      onTap: isLoading
                          ? null
                          : () async {
                              final success = await context
                                  .read<DeviceScanController>()
                                  .selectDevice(d);

                              if (!mounted) return;

                              if (success) {
                                context
                                    .read<DeviceSessionController>()
                                    .connectDevice(d);

                                context.go(AppRoutes.deviceConnected);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      scan.errorMessage ?? 'Failed to connect',
                                    ),
                                  ),
                                );
                              }
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
  final VoidCallback? onTap;
  final bool isLoading;

  const _DeviceCard({
    required this.name,
    required this.timeText,

    required this.onTap,
    required this.isLoading,
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
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF7DF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Available',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
