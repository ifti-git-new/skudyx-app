import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_controller.dart';

import '../../../../core/navigation/app_routes.dart';
import '../widgets/auth_ui_constants.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  static const int _len = 6; // ✅ 6 DIGITS

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_len, (_) => TextEditingController());
    _nodes = List.generate(_len, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit => _controllers.every((c) => c.text.trim().length == 1);

  String get _otp => _controllers.map((c) => c.text.trim()).join();

  void _fillFromPaste(int startIndex, String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    for (int i = 0; i < digits.length && (startIndex + i) < _len; i++) {
      _controllers[startIndex + i].text = digits[i];
    }
    setState(() {});
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _fillFromPaste(index, value);
      return;
    }

    if (value.isNotEmpty && index < _len - 1) {
      _nodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  Future<void> _submit(String email) async {
    if (!_canSubmit || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final controller = context.read<AuthController>();

    final success = await controller.verifyUserOtp(email: email, otp: _otp);
    //final success = true;

    if (!mounted) return;

    if (success) {
      _isLoading = false;
      context.go(AppRoutes.registerSuccess);
    } else {
      setState(() {
        _error = controller.otpErrorMessage ?? 'Invalid OTP';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = GoRouterState.of(context).extra as String;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Verify', style: AppTextStyles.h1),
            const SizedBox(height: 10),
            Text(
              'Enter the 6-digit code sent to\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AuthUi.subText),
            ),
            const SizedBox(height: 32),

            /// ✅ OTP BOXES
            LayoutBuilder(
              builder: (context, constraints) {
                final totalSpacing = (_len - 1) * 8; // spacing between boxes
                final availableWidth = constraints.maxWidth - totalSpacing;

                final boxWidth = availableWidth / _len;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_len, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i == _len - 1 ? 0 : 8),
                      child: SizedBox(
                        width: boxWidth.clamp(40, 60), // ✅ min 40, max 60
                        height: boxWidth.clamp(40, 60),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _nodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AuthUi.fieldFill,
                            //errorText: _error != null && i == 0 ? '' : null,
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AuthUi.fieldBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AuthUi.navy,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (v) => _onChanged(i, v),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            /// ✅ ERROR MESSAGE
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            const SizedBox(height: 22),

            /// ✅ SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthUi.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _canSubmit && !_isLoading
                    ? () => _submit(email)
                    : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            /// ✅ RESEND
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Didn't receive OTP? ",
                  style: TextStyle(fontSize: 13, color: AuthUi.subText),
                ),
                Text(
                  'Resend',
                  style: TextStyle(
                    fontSize: 13,
                    color: AuthUi.navy,
                    fontWeight: FontWeight.w800,
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
