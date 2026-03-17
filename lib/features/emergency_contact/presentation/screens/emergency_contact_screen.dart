import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/storage/app_prefs.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/emergency/presentation/controllers/emergency_contact_controller.dart';
import 'package:skudyx/features/emergency/presentation/models/emergency_contact_model.dart';

class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Watch the controller. This triggers a rebuild when saveContact()
    // or init() calls notifyListeners().
    final controller = context.watch<EmergencyContactController>();
    final prefs = context.read<AppPrefs>();

    // ✅ Logical Check: If the preference is true OR the controller has a contact loaded
    if (prefs.ecAdded || controller.contact != null) {
      return const _OverviewView();
    }

    return const _WhyWeNeedThisView();
  }
}

class _WhyWeNeedThisView extends StatelessWidget {
  const _WhyWeNeedThisView();

  static const _navy = Color(0xFF081B4A);
  static const _textGrey = Color(0xFF666666);

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
                // Container(
                //   width: 84,
                //   height: 84,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(18),
                //     gradient: const LinearGradient(
                //       colors: [Color(0xFF0B1220), Color(0xFF0077FF)],
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //     ),
                //   ),
                //   child: const Icon(
                //     Icons.person,
                //     color: Colors.white,
                //     size: 34,
                //   ),
                // ),
                Image.asset('assets/images/add_emergency_contact.png'),
                const SizedBox(height: 32),
                Text(
                  'Why we need this',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Description
                Text(
                  'Your emergency contact is the first person we notify when you press the SkudyX button. Adding this now helps us reach someone you trust as quickly as possible during an emergency.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2light.copyWith(
                    fontSize: 16,
                    height: 1.5,
                    color: _textGrey,
                  ),
                ),
                const SizedBox(height: 30),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Add Emergency Contact',
                        style: AppTextStyles.textfont16.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EmergencyContactController>();

    // Fallback logic remains to prevent crashes if data is still loading
    final contact =
        c.contact ??
        const EmergencyContactModel(
          firstName: 'Jerome',
          lastName: 'Bell',
          phone: '+12 345 6789',
          email: 'jerome.bell@yourmail.com',
          relation: '-',
          address: '21 East  Dhanmondi, Dhaka, Bangladesh',
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Emergency Contact',
                    style: AppTextStyles.textfont16.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
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
              _VerifyRow(
                label: 'Phone Number',
                value: contact.phone,
                verified: c.phoneVerified,
                onTap: c.phoneVerified
                    ? null
                    : () => _startVerifyFlow(context, type: _VerifyType.phone),
              ),
              const SizedBox(height: 16),
              _VerifyRow(
                label: 'Email',
                value: contact.email,
                verified: c.emailVerified,
                onTap: c.emailVerified
                    ? null
                    : () => _startVerifyFlow(context, type: _VerifyType.email),
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

  Future<void> _startVerifyFlow(
    BuildContext context, {
    required _VerifyType type,
  }) async {
    final shouldSend = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ConfirmationSheet(type: type),
    );

    if (shouldSend != true) return;

    if (!context.mounted) return;

    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
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

// --- Internal Helper Widgets ---

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textfont.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.textfont16.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _VerifyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool verified;
  final VoidCallback? onTap;

  const _VerifyRow({
    required this.label,
    required this.value,
    required this.verified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = verified ? 'Verified' : 'Not verified';
    final badgeBg = verified
        ? const Color(0xFFDFF7DF)
        : const Color(0xFFFFE9A6);
    final badgeFg = verified
        ? const Color(0xFF16A34A)
        : const Color(0xFF92400E);

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
                  style: AppTextStyles.textfont.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.textfont16.copyWith(
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
              style: AppTextStyles.textfont.copyWith(
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

class _ConfirmationSheet extends StatelessWidget {
  final _VerifyType type;
  const _ConfirmationSheet({required this.type});

  @override
  Widget build(BuildContext context) {
    final target = type == _VerifyType.email ? 'email' : 'phone';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 10,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirmation',
                style: AppTextStyles.textfont16.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'An authentication code will be sent to this $target.',
              style: AppTextStyles.textfont.copyWith(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.35,
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
                        backgroundColor: const Color(0xFFE5E7EB),
                        foregroundColor: const Color(0xFF081B4A),
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
                        backgroundColor: const Color(0xFF081B4A),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    for (var n in nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final src = widget.type == _VerifyType.email ? 'Email' : 'Phone';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 10,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirmation',
                style: AppTextStyles.textfont16.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the authentication code from $src to\nverify.',
              style: AppTextStyles.textfont.copyWith(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(len, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i == len - 1 ? 0 : 10),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: TextField(
                      controller: controllers[i],
                      focusNode: nodes[i],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
