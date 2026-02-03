import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../widgets/auth_ui_constants.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  static const int _len = 5;

  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _nodes = List.generate(_len, (_) => FocusNode());

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

  String get otp => _controllers.map((e) => e.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // If user pasted multiple chars, keep last char
      _controllers[index].text = value.characters.last;
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
    }

    if (value.isNotEmpty) {
      if (index < _len - 1) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
      }
    }
    setState(() {});
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
      _controllers[index - 1].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index - 1].text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        otp.length == _len && !_controllers.any((c) => c.text.isEmpty);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 140),

              const Text(
                'Verify',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'An authentication code has been sent to your\nemail.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AuthUi.subText,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_len, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i == _len - 1 ? 0 : 12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Focus(
                        onKeyEvent: (node, event) {
                          // Detect backspace on desktop/web; on mobile TextField handles it
                          if (event.logicalKey.keyLabel == 'Backspace') {
                            _onBackspace(i);
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _nodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AuthUi.fieldFill,
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
                    ),
                  );
                }),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthUi.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canSubmit
                      ? () {
                          // UI-only: Later verify OTP API then show success
                          // context.go(AppRoutes.registerSuccess);
                        }
                      : null,
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive OTP - Request again  ",
                    style: TextStyle(
                      fontSize: 13,
                      color: AuthUi.subText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: resend OTP API later
                    },
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        fontSize: 13,
                        color: AuthUi.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
