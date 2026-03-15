import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/cases/data/remote/case_api.dart';

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
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
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
  bool _isExpanded = false;

  bool _starting = false;
  bool _tracking = false;

  String? _caseId;
  String? _caseName;

  Timer? _timer;
  bool _tickInFlight = false;

  int _successUpdates = 0;
  int _failedUpdates = 0;

  bool _statusUpdating = false;

  final List<Map<String, dynamic>> _allCoordinates = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _ensureLocationReady(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Location permission denied.')),
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Location permission permanently denied.'),
        ),
      );
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

  Future<void> _startCaseAndTracking({
    required BuildContext context,
    required bool isTest,
    required String caseName,
  }) async {
    if (_starting || _tracking) return;

    final ok = await _ensureLocationReady(context);
    if (!ok) return;

    final scaffold = ScaffoldMessenger.of(context);
    final caseApi = context.read<CaseApi>();

    setState(() {
      _starting = true;
      _caseName = caseName;
      _caseId = null;
      _successUpdates = 0;
      _failedUpdates = 0;
      _allCoordinates.clear();
    });

    scaffold.showSnackBar(SnackBar(content: Text('Creating $caseName...')));

    try {
      final firstPos = await _getCurrentPosition();

      final caseData = await caseApi.triggerCase(
        latitude: firstPos.latitude,
        longitude: firstPos.longitude,
        isTest: isTest,
      );

      final createdCaseId = (caseData['case_id'] ?? '').toString();
      if (createdCaseId.isEmpty) {
        throw Exception('Missing case_id from backend response');
      }

      if (!mounted) return;
      setState(() {
        _caseId = createdCaseId;
        _tracking = true;
        _starting = false;
      });

      scaffold.showSnackBar(
        SnackBar(content: Text('$caseName started! Case ID: $createdCaseId')),
      );

      await _sendOneTick(caseApi);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!_tracking) return;
        if (_tickInFlight) return;

        _tickInFlight = true;
        try {
          await _sendOneTick(caseApi);
        } finally {
          _tickInFlight = false;
        }
      });
    } on DioException catch (e) {
      final String msg =
          ((e.response?.data as Map?)?['message']?.toString()) ??
          'Failed to start case.';
      scaffold.showSnackBar(SnackBar(content: Text(msg)));

      if (!mounted) return;
      setState(() {
        _starting = false;
        _tracking = false;
        _caseId = null;
        _caseName = null;
      });

      _timer?.cancel();
      _timer = null;
    } catch (_) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong starting the case.'),
        ),
      );

      if (!mounted) return;
      setState(() {
        _starting = false;
        _tracking = false;
        _caseId = null;
        _caseName = null;
      });

      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _sendOneTick(CaseApi caseApi) async {
    final id = _caseId;
    if (id == null) return;

    try {
      final pos = await _getCurrentPosition();

      _allCoordinates.add({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await caseApi.updateLocation(
        caseId: id,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      _successUpdates += 1;
      if (mounted) setState(() {});
    } catch (e) {
      _failedUpdates += 1;
      if (mounted) setState(() {});
      if (kDebugMode) {
        // ignore: avoid_print
        print('Tick failed: $e');
      }
    }
  }

  Future<String?> _askNote(BuildContext context, String status) async {
    final ctrl = TextEditingController(
      text: 'Do you want to mark $status from app test button?',
    );

    final note = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Update Status: $status'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    ctrl.dispose();
    return note;
  }

  Future<void> _updateFinalStatus(BuildContext context, String status) async {
    final id = _caseId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No case_id found. Start a case first.')),
      );
      return;
    }
    if (_statusUpdating) return;

    final caseApi = context.read<CaseApi>();
    final note = await _askNote(context, status);
    if (!mounted) return;
    if (note == null) return; // cancelled

    setState(() => _statusUpdating = true);

    try {
      await caseApi.updateStatus(caseId: id, status: status, note: note);

      // Stop tracking when final status is sent
      _timer?.cancel();
      _timer = null;

      setState(() {
        _tracking = false;
        _starting = false;
        _tickInFlight = false;
        _statusUpdating = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Case $id updated to $status')));
    } on DioException catch (e) {
      final String msg =
          ((e.response?.data as Map?)?['message']?.toString()) ??
          'Failed to update status.';
      setState(() => _statusUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      setState(() => _statusUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong updating status.')),
      );
    }
  }

  Future<void> _endTracking(BuildContext context) async {
    if (!_tracking && !_starting) return;

    _timer?.cancel();
    _timer = null;

    final endedCaseId = _caseId;
    final endedName = _caseName;
    final total = _allCoordinates.length;

    setState(() {
      _tracking = false;
      _starting = false;
      _caseId = null;
      _caseName = null;
      _tickInFlight = false;
    });

    if (kDebugMode) {
      // ignore: avoid_print
      print('=== END CASE TRACKING ===');
      // ignore: avoid_print
      print(
        'case_name=$endedName case_id=$endedCaseId total_points=$total '
        'success=$_successUpdates failed=$_failedUpdates',
      );
      // ignore: avoid_print
      print(_allCoordinates);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ended ${endedName ?? 'case'} (${endedCaseId ?? '-'}) '
          '- points: $total (ok $_successUpdates / fail $_failedUpdates)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _starting
        ? 'Starting...'
        : _tracking
        ? 'Tracking ON'
        : 'Tracking OFF';

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

        if (kDebugMode) ...[
          const SizedBox(height: 24),
          ExpansionTile(
            title: const Text(
              'Internal Testing (Dev/QA Only)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) =>
                setState(() => _isExpanded = expanded),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$statusText\n'
                        'Case: ${_caseName ?? '-'}\n'
                        'case_id: ${_caseId ?? (_starting ? '(creating...)' : '-')}\n'
                        'Points: ${_allCoordinates.length}\n'
                        'Updates: ok $_successUpdates / fail $_failedUpdates',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),

                    //--TEMPORARILY REMOVED - TEST BUTTONS FOR STARTING CASES AND TRACKING--//
                    // Existing start buttons (unchanged behavior)
                    // ElevatedButton(
                    //   onPressed: (_tracking || _starting || _statusUpdating)
                    //       ? null
                    //       : () => _startCaseAndTracking(
                    //           context: context,
                    //           isTest: true,
                    //           caseName: 'Test Case',
                    //         ),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.blue,
                    //     minimumSize: const Size(double.infinity, 48),
                    //   ),
                    //   child: const Text('Start Test Case'),
                    // ),
                    // const SizedBox(height: 12),

                    // ElevatedButton(
                    //   onPressed: (_tracking || _starting || _statusUpdating)
                    //       ? null
                    //       : () => _startCaseAndTracking(
                    //           context: context,
                    //           isTest: false,
                    //           caseName: 'Basic Case',
                    //         ),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.orange,
                    //     minimumSize: const Size(double.infinity, 48),
                    //   ),
                    //   child: const Text('Start Basic Case'),
                    // ),
                    // const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: (_tracking || _starting || _statusUpdating)
                          ? null
                          : () => _startCaseAndTracking(
                              context: context,
                              isTest: false,
                              caseName: 'Live Case',
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          99,
                          197,
                          106,
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'Start Live Case',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // The "End" button is now removed to encourage using the status update buttons for a more realistic flow.
                    //temporary off now
                    // OutlinedButton(
                    //   onPressed: (_tracking || _starting)
                    //       ? () => _endTracking(context)
                    //       : null,
                    //   style: OutlinedButton.styleFrom(
                    //     minimumSize: const Size(double.infinity, 48),
                    //   ),
                    //   child: const Text('End'),
                    // ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // NEW: Status update buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_caseId == null || _statusUpdating)
                                ? null
                                : () => _updateFinalStatus(context, 'Resolved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: _statusUpdating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Resolved',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_caseId == null || _statusUpdating)
                                ? null
                                : () =>
                                      _updateFinalStatus(context, 'Unresolved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                179,
                                32,
                                32,
                              ),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: const Text(
                              'Unresolved',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_caseId == null || _statusUpdating)
                            ? null
                            : () => _updateFinalStatus(context, 'False'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7280),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: const Text(
                          'False',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
