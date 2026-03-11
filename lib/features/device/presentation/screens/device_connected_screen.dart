import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/network/dio_debug_interceptor.dart'; // If you have this
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class DeviceConnectedScreen extends StatefulWidget {
  const DeviceConnectedScreen({super.key});

  @override
  State<DeviceConnectedScreen> createState() => _DeviceConnectedScreenState();
}

class _DeviceConnectedScreenState extends State<DeviceConnectedScreen> {
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE5E7EB);

  static const Color _green = Color(0xFF22C55E);
  static const Color _greenSoft = Color(0xFFDFF7DF);

  static const Color _orange = Color(0xFFF59E0B);
  static const Color _orangeSoft = Color(0xFFFFEDD5);

  static const Color _textMuted = Color(0xFF6B7280);

  bool isActiveMode = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final statusColor = isActiveMode ? _green : _orange;
    final statusSoftColor = isActiveMode ? _greenSoft : _orangeSoft;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final circleSize = constraints.maxWidth * 0.38;
            final deviceSize = circleSize * 0.55;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),

                  const SizedBox(height: 26),

                  /// ✅ DEVICE CIRCLE
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
                                    color: Colors.black.withValues(alpha: 0.02),
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

                        /// ✅ TICK BADGE
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

                  /// ✅ MODE SWITCHER
                  _ModeSwitcher(
                    isActive: isActiveMode,
                    onChanged: (val) {
                      setState(() {
                        isActiveMode = val;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  /// ✅ BLE CARD
                  _BleCard(
                    statusColor: statusColor,
                    softColor: statusSoftColor,
                  ),

                  const SizedBox(height: 28),

                  const _SafetySection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.pop(),
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

                /// ✅ DISCONNECT ON TAP
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    HapticFeedback.mediumImpact();

                    /// TODO: Call your real BLE disconnect logic here

                    context.go(AppRoutes.deviceList);
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
  const _SafetySection();

  @override
  State<_SafetySection> createState() => _SafetySectionState();
}

class _SafetySectionState extends State<_SafetySection> {
  bool _isExpanded = false; // For internal testing section

  Future<void> _triggerCase(
    BuildContext context,
    bool isTest,
    String caseName,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    final caseApi = context.read<CaseApi>();

    // Get real-time location
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final double lat = position.latitude;
    final double long = position.longitude;

    // Show loading
    scaffold.showSnackBar(SnackBar(content: Text('Creating $caseName...')));

    try {
      final caseData = await caseApi.triggerCase(
        latitude: lat,
        longitude: long,
        isTest: isTest,
      );

      final caseId = caseData['case_id'] ?? 'Unknown';
      scaffold.showSnackBar(
        SnackBar(content: Text('$caseName created! Case ID: $caseId')),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to create case.';
      scaffold.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Something went wrong.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

        // Internal Testing Buttons (Debug Only)
        if (kDebugMode) ...[
          const SizedBox(height: 24),
          ExpansionTile(
            title: const Text(
              'Internal Testing (Dev/QA Only)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _triggerCase(context, true, 'Test Case'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Create Test Case'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          _triggerCase(context, false, 'Basic Case'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Create Basic Case'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          _triggerCase(context, false, 'Live Case'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Create Live Case'),
                    ),
                  ],
                ),
              ),
            ],
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
                      ? const Color(0xFFF0C5132)
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _DeviceConnectedScreenState._textMuted,
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DeviceConnectedScreenState._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
