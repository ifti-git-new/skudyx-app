import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_controller.dart';

class DeleteAccountFlow {
  /// Call this from Settings -> Delete Account onTap
  static Future<void> start(BuildContext context) async {
    // 1) Warning (Yes/No)
    final yes = await _showWarningSheet(context);
    if (yes != true) return;

    // 2) Confirmation (Later/Send)
    final send = await _showConfirmationSheet(context);
    if (send != true) return;

    // 3) OTP (Cancel/Done)
    final otpOk = await _showOtpSheet(context);
    if (otpOk != true) return;

    // 4) Success (OK)
    await _showSuccessSheet(context);

    // After OK (or X) -> clear data + logout + route login
    if (!context.mounted) return;
    await context.read<AuthController>().logout();

    if (!context.mounted) return;
    GoRouter.of(context).go(AppRoutes.login);
  }

  static Future<bool?> _showWarningSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return _BaseSheet(
          title: 'Warning!',
          message: 'Do you want to delete your SkudyX Account?',
          leftButton: _SheetButton(
            text: 'Yes',
            type: _ButtonType.secondary,
            onTap: () => Navigator.pop(sheetContext, true),
          ),
          rightButton: _SheetButton(
            text: 'No',
            type: _ButtonType.primary,
            onTap: () => Navigator.pop(sheetContext, false),
          ),
          onClose: () => Navigator.pop(sheetContext, false),
        );
      },
    );
  }

  static Future<bool?> _showConfirmationSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return _BaseSheet(
          title: 'Confirmation',
          message: 'An authentication code will be sent to your email.',
          leftButton: _SheetButton(
            text: 'Later',
            type: _ButtonType.secondary,
            onTap: () => Navigator.pop(sheetContext, false),
          ),
          rightButton: _SheetButton(
            text: 'Send',
            type: _ButtonType.primary,
            onTap: () => Navigator.pop(sheetContext, true),
          ),
          onClose: () => Navigator.pop(sheetContext, false),
        );
      },
    );
  }

  static Future<bool?> _showOtpSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => const _OtpSheet(),
    );
  }

  static Future<void> _showSuccessSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return _BaseSheet(
          title: 'Warning!',
          message: 'Your SkudyX account is deleted successfully.',
          leftButton: null,
          rightButton: _SheetButton(
            text: 'OK',
            type: _ButtonType.primary,
            onTap: () => Navigator.pop(sheetContext),
          ),
          onClose: () => Navigator.pop(sheetContext),
        );
      },
    );
  }
}

enum _ButtonType { primary, secondary }

class _SheetButton {
  final String text;
  final _ButtonType type;
  final VoidCallback onTap;

  const _SheetButton({
    required this.text,
    required this.type,
    required this.onTap,
  });
}

class _BaseSheet extends StatelessWidget {
  final String title;
  final String message;
  final _SheetButton? leftButton;
  final _SheetButton? rightButton;
  final VoidCallback onClose;

  const _BaseSheet({
    required this.title,
    required this.message,
    required this.leftButton,
    required this.rightButton,
    required this.onClose,
  });

  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
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
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: _muted,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                if (leftButton != null) ...[
                  Expanded(child: _SheetActionButton(btn: leftButton!)),
                  const SizedBox(width: 12),
                ],
                if (rightButton != null)
                  Expanded(child: _SheetActionButton(btn: rightButton!)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final _SheetButton btn;
  const _SheetActionButton({required this.btn});

  static const _navy = Color(0xFF081B4A);

  @override
  Widget build(BuildContext context) {
    final isPrimary = btn.type == _ButtonType.primary;

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isPrimary ? _navy : const Color(0xFFE5E7EB),
          foregroundColor: isPrimary ? Colors.white : _navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: btn.onTap,
        child: Text(
          btn.text,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// OTP length = 5 (as you confirmed)
class _OtpSheet extends StatefulWidget {
  const _OtpSheet();

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _fill = Color(0xFFF6F7F9);

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
    for (final c in controllers) {
      c.dispose();
    }
    for (final n in nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirmation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Use the authentication code from Email to\nverify.',
                style: TextStyle(fontSize: 14, color: _muted, height: 1.35),
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
                        fillColor: _fill,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _navy,
                            width: 1.4,
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {});
                        if (v.isNotEmpty && i < len - 1) {
                          nodes[i + 1].requestFocus();
                        }
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
                        foregroundColor: _navy,
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
                        backgroundColor: _navy,
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
