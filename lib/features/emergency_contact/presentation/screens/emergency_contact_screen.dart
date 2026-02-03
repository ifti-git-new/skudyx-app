import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/emergency/presentation/controllers/emergency_contact_controller.dart';
// import '../controllers/emergency_contact_controller.dart';

class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EmergencyContactController>();

    if (!c.isAdded) {
      return const _WhyWeNeedThisView();
    }

    return const _OverviewView();
  }
}

class _WhyWeNeedThisView extends StatelessWidget {
  const _WhyWeNeedThisView();

  static const _navy = Color(0xFF081B4A);
  static const _sub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // icon placeholder (replace with your asset if you have one)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1220), Color(0xFF0077FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Why we need this',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your emergency contact is the first person we\nnotify when you press the SkudyX button.\nAdding this now helps us reach someone you\ntrust as quickly as possible during an\nemergency.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: _sub, height: 1.35),
                ),
                const SizedBox(height: 22),

                // Grey pill button like screenshot
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: _navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () =>
                        context.push(AppRoutes.emergencyContactEdit),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Add Emergency Contact',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView();

  static const _sub = Color(0xFF6B7280);
  static const _navy = Color(0xFF081B4A);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EmergencyContactController>();
    final contact = c.contact!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top bar: title + edit icon
              Row(
                children: [
                  const Text(
                    'Emergency Contact',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => context.push(AppRoutes.emergencyContactEdit),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _LabelValue(label: 'Name', value: contact.fullName),

              const SizedBox(height: 16),

              // Phone row + badge
              _TapToVerifyRow(
                label: 'Phone Number',
                value: contact.phone,
                badgeText: c.phoneVerified ? 'Verified' : 'Not verified',
                badgeBg: c.phoneVerified
                    ? const Color(0xFFDFF7DF)
                    : const Color(0xFFFFE9A6),
                badgeFg: c.phoneVerified
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF92400E),
                onTap: c.phoneVerified
                    ? null
                    : () => _showVerifyFlow(context, type: _VerifyType.phone),
              ),

              const SizedBox(height: 16),

              _TapToVerifyRow(
                label: 'Email',
                value: contact.email,
                badgeText: c.emailVerified ? 'Verified' : 'Not verified',
                badgeBg: c.emailVerified
                    ? const Color(0xFFDFF7DF)
                    : const Color(0xFFFFE9A6),
                badgeFg: c.emailVerified
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF92400E),
                onTap: c.emailVerified
                    ? null
                    : () => _showVerifyFlow(context, type: _VerifyType.email),
              ),

              const SizedBox(height: 16),
              _LabelValue(label: 'Relation', value: contact.relation),
              const SizedBox(height: 16),
              _LabelValue(label: 'Address', value: contact.address),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showVerifyFlow(
    BuildContext context, {
    required _VerifyType type,
  }) async {
    // 1) confirmation sheet
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConfirmSendSheet(type: type),
    );

    if (send != true) return;

    // 2) otp sheet
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OtpSheet(type: type),
    );

    if (verified == true && context.mounted) {
      final controller = context.read<EmergencyContactController>();
      if (type == _VerifyType.phone) {
        await controller.setPhoneVerified(true);
      } else {
        await controller.setEmailVerified(true);
      }
    }
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValue({required this.label, required this.value});

  static const _sub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _sub,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _TapToVerifyRow extends StatelessWidget {
  final String label;
  final String value;
  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final VoidCallback? onTap;

  const _TapToVerifyRow({
    required this.label,
    required this.value,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    required this.onTap,
  });

  static const _sub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _VerifyType { phone, email }

class _ConfirmSendSheet extends StatelessWidget {
  final _VerifyType type;
  const _ConfirmSendSheet({required this.type});

  static const _navy = Color(0xFF081B4A);
  static const _sub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final label = type == _VerifyType.email ? 'email' : 'phone';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context, false),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirmation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'An authentication code will be sent to this $label.',
                style: const TextStyle(fontSize: 14, color: _sub, height: 1.35),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE5E7EB),
                        foregroundColor: _navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Later',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Send',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpSheet extends StatefulWidget {
  final _VerifyType type;
  const _OtpSheet({required this.type});

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  static const int len = 5;
  final controllers = List.generate(len, (_) => TextEditingController());
  final nodes = List.generate(len, (_) => FocusNode());

  bool get canDone => controllers.every((c) => c.text.trim().length == 1);

  @override
  void dispose() {
    for (final c in controllers) c.dispose();
    for (final n in nodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.type == _VerifyType.email ? 'Email' : 'Phone';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context, false),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirmation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Use the authentication code from $label to\nverify.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(len, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i == len - 1 ? 0 : 10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: TextField(
                      controller: controllers[i],
                      focusNode: nodes[i],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF6F7F9),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF081B4A),
                            width: 1.4,
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {});
                        if (v.isNotEmpty && i < len - 1)
                          nodes[i + 1].requestFocus();
                      },
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE5E7EB),
                        foregroundColor: const Color(0xFF081B4A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF081B4A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: canDone
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
