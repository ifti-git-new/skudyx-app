import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/device/presentation/controllers/device_session_controller.dart';

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
    final session = context.watch<DeviceSessionController>();

    final width = MediaQuery.of(context).size.width;
    final statusColor = isActiveMode ? _green : _orange;
    final statusSoftColor = isActiveMode ? _greenSoft : _orangeSoft;

    if (!session.isConnected) {
      return const Scaffold(
        backgroundColor: _bg,
        body: SafeArea(child: Center(child: Text('No device connected'))),
      );
    }

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
  const _SafetySection();

  @override
  State<_SafetySection> createState() => _SafetySectionState();
}

class _SafetySectionState extends State<_SafetySection> {
  bool _isExpanded = false;

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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();

    final statusText = session.starting
        ? 'Starting...'
        : session.tracking
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
                        'Case: ${session.caseName ?? '-'}\n'
                        'case_id: ${session.caseId ?? (session.starting ? '(creating...)' : '-')}\n'
                        'Points: ${session.coordinates.length}\n'
                        'Updates: ok ${session.successUpdates} / fail ${session.failedUpdates}',
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
                      onPressed:
                          (session.tracking ||
                              session.starting ||
                              session.statusUpdating)
                          ? null
                          : () async {
                              final ok = await context
                                  .read<DeviceSessionController>()
                                  .startCase(
                                    isTest: false,
                                    caseName: 'Live Case',
                                  );

                              if (!context.mounted) return;

                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      session.lastError ??
                                          'Failed to start case',
                                    ),
                                  ),
                                );
                              }
                            },
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
                            onPressed:
                                (session.caseId == null ||
                                    session.statusUpdating)
                                ? null
                                : () async {
                                    final note = await _askNote(
                                      context,
                                      'Resolved',
                                    );
                                    if (!context.mounted || note == null)
                                      return;

                                    final ok = await context
                                        .read<DeviceSessionController>()
                                        .updateFinalStatus(
                                          status: 'Resolved',
                                          note: note,
                                        );

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Case updated to Resolved'
                                              : (session.lastError ??
                                                    'Failed to update status'),
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: session.statusUpdating
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
                            onPressed:
                                (session.caseId == null ||
                                    session.statusUpdating)
                                ? null
                                : () async {
                                    final note = await _askNote(
                                      context,
                                      'Unresolved',
                                    );
                                    if (!context.mounted || note == null)
                                      return;

                                    final ok = await context
                                        .read<DeviceSessionController>()
                                        .updateFinalStatus(
                                          status: 'Unresolved',
                                          note: note,
                                        );

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Case updated to Unresolved'
                                              : (session.lastError ??
                                                    'Failed to update status'),
                                        ),
                                      ),
                                    );
                                  },
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
                        onPressed:
                            (session.caseId == null || session.statusUpdating)
                            ? null
                            : () async {
                                final note = await _askNote(context, 'False');
                                if (!context.mounted || note == null) return;

                                final ok = await context
                                    .read<DeviceSessionController>()
                                    .updateFinalStatus(
                                      status: 'False',
                                      note: note,
                                    );

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Case updated to False'
                                          : (session.lastError ??
                                                'Failed to update status'),
                                    ),
                                  ),
                                );
                              },
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

                    if (session.lastError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        session.lastError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
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
