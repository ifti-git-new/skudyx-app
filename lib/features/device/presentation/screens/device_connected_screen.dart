import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/config/app_config.dart';
import 'package:skudyx/core/config/flavors.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/services/audio_foreground_service.dart'; // ✅ ADDED
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/cases/presentation/controllers/live_case_call_controller.dart';
import 'package:skudyx/features/device/presentation/controllers/device_session_controller.dart';

class DeviceConnectedScreen extends StatefulWidget {
  const DeviceConnectedScreen({super.key});

  @override
  State<DeviceConnectedScreen> createState() => _DeviceConnectedScreenState();
}

class _DeviceConnectedScreenState extends State<DeviceConnectedScreen> {
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _green = Color(0xFF22C55E);
  static const Color _greenSoft = Color(0xFFDFF7DF);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _orangeSoft = Color(0xFFFFEDD5);

  bool isActiveMode = true;

  // ✅ ADDED: request Android 13+ notification permission for foreground service
  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     AudioForegroundService.requestPermissions();
  //   });
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // ✅ Request notification permission for Android 13+
        if (defaultTargetPlatform == TargetPlatform.android) {
          final status = await Permission.notification.status;
          if (status.isDenied || status.isRestricted) {
            await Permission.notification.request();
          }
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Permission request failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();
    final config = context.read<AppConfig>();
    final showInternalTesting = config.flavor != Flavor.prod;
    final width = MediaQuery.of(context).size.width;
    final circleSize = width * 0.38;
    final statusColor = isActiveMode ? _green : _orange;
    final statusSoftColor = isActiveMode ? _greenSoft : _orangeSoft;

    if (!session.isConnected) {
      return const Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: Text(
              'No device connected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 26),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor, width: 2.5),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/images/ble_device.png",
                            height: 133,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: circleSize * 0.22,
                        height: circleSize * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _ModeSwitcher(
                isActive: isActiveMode,
                onChanged: (val) => setState(() => isActiveMode = val),
              ),
              const SizedBox(height: 28),
              _BleCard(statusColor: statusColor, softColor: statusSoftColor),
              const SizedBox(height: 28),
              _SafetySection(showInternalTesting: showInternalTesting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Disconnect",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _ModeSwitcher({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            _buildTab(
              text: "Active mode",
              selected: isActive,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(true);
              },
            ),
            _buildTab(
              text: "Test mode",
              selected: !isActive,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _BleCard extends StatelessWidget {
  final Color statusColor;
  final Color softColor;

  const _BleCard({required this.statusColor, required this.softColor});

  @override
  Widget build(BuildContext context) {
    final session = context.read<DeviceSessionController>();

    return _ResponsiveCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text(
                  "BLE Device",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await session.disconnectDevice();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device disconnected')),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Connected",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const _InfoRow(title: "Battery", value: "50%"),
          const Divider(height: 1),
          const _InfoRow(title: "Subscription Plan", value: "Basic"),
        ],
      ),
    );
  }
}

class _SafetySection extends StatefulWidget {
  final bool showInternalTesting;
  const _SafetySection({required this.showInternalTesting});

  @override
  State<_SafetySection> createState() => _SafetySectionState();
}

class _SafetySectionState extends State<_SafetySection> {
  bool _routingToTracking = false;

  Future<void> _startLiveCase(BuildContext context) async {
    final session = context.read<DeviceSessionController>();

    setState(() => _routingToTracking = true);

    try {
      final ok = await session.startCase(isTest: false, caseName: 'Live Case');

      if (!mounted) return;

      if (!ok || session.caseId == null) {
        setState(() => _routingToTracking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(session.lastError ?? 'Failed to start case'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ✅ Initialize LiveCaseCallController and store in session controller
      final config = context.read<AppConfig>();
      final liveCallController = LiveCaseCallController(
        socketBaseUrl: config.wsUrl,
        uploadBaseUrl: config.apiBaseUrl,
        uploadEndpoint: '/api/v1/cases/upload-final-audio',
        caseId: session.caseId.toString(),
        isCaller: true,
      );

      await liveCallController.start();

      // ✅ Store controller in DeviceSessionController for persistence
      session.setLiveCallController(liveCallController);

      if (!mounted) return;

      setState(() => _routingToTracking = false);

      // ✅ USE GoRouter navigation (route is OUTSIDE ShellRoute → no bottom nav)
      if (mounted) {
        context.go(AppRoutes.liveCaseTracking);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _routingToTracking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 80)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();

    final bool isLoading =
        _routingToTracking || session.starting || session.statusUpdating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Safety Information Sharing:",
              style: AppTextStyles.textfont.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.info_rounded),
          ],
        ),
        const SizedBox(height: 16),
        const _SafetyTile(title: "Share My Location", active: true),
        const SizedBox(height: 12),
        const _SafetyTile(title: "Live Movement Tracking"),
        const SizedBox(height: 12),
        const _SafetyTile(title: "Live Audio Sharing"),
        if (widget.showInternalTesting) ...[
          const SizedBox(height: 24),
          const Text(
            'Internal Testing (Dev/QA Only)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.red,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (isLoading || session.tracking)
                ? null
                : () => _startLiveCase(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const Row(
                      key: ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Starting...',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      key: ValueKey('idle'),
                      'Start Live Case',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SafetyTile extends StatelessWidget {
  final String title;
  final bool active;

  const _SafetyTile({required this.title, this.active = false});

  @override
  Widget build(BuildContext context) {
    return _ResponsiveCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Colors.green.shade100 : const Color(0XffFEDAD9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                active ? "Active" : "Inactive",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active
                      ? const Color(0xFF16A34A)
                      : const Color(0Xff8E1F0B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  static const _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: _textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ResponsiveCard extends StatelessWidget {
  final Widget child;

  const _ResponsiveCard({required this.child});

  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
