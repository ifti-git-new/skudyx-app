import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_routes.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _navy = Color(0xFF081B4A);
  static const Color _hint = Color(0xFF9AA3AF);
  static const Color _subText = Color(0xFF6B7280);
  static const Color _fieldFill = Color(0xFFF6F7F9);
  static const Color _fieldBorder = Color(0xFFE5E7EB);

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 110),

                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your email and password to log in',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: _subText, height: 1.3),
                ),

                const SizedBox(height: 34),

                _SkTextField(
                  controller: _emailCtrl,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  fillColor: _fieldFill,
                  borderColor: _fieldBorder,
                  hintColor: _hint,
                ),

                const SizedBox(height: 16),

                _SkTextField(
                  controller: _passCtrl,
                  hintText: 'Password',
                  obscureText: _obscure,
                  fillColor: _fieldFill,
                  borderColor: _fieldBorder,
                  hintColor: _hint,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _hint,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _fieldBorder),
                                color: Colors.white,
                              ),
                              child: _rememberMe
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: _navy,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 13,
                                color: _subText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.forgotPassword),
                      child: const Text(
                        'Forgot Password ?',
                        style: TextStyle(
                          fontSize: 13,
                          color: _navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      // UI-only for now
                      await auth.mockLogin(isNewUser: false);
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don’t have an account?  ",
                      style: TextStyle(
                        fontSize: 13,
                        color: _subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 13,
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                Row(
                  children: const [
                    Expanded(child: Divider(color: _fieldBorder, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Login with',
                        style: TextStyle(
                          fontSize: 13,
                          color: _subText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: _fieldBorder, thickness: 1)),
                  ],
                ),

                const SizedBox(height: 18),

                // Platform logic:
                // Android -> Google, iOS -> Apple
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (Platform.isIOS)
                      _SocialCircleButton(
                        onTap: () async => auth.signInWithApple(),
                        child: const Icon(
                          Icons.apple,
                          size: 26,
                          color: Colors.black,
                        ),
                      )
                    else
                      _SocialCircleButton(
                        onTap: () async => auth.signInWithGoogle(),
                        child: SvgPicture.asset(
                          'assets/icons/google.svg',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Color fillColor;
  final Color borderColor;
  final Color hintColor;

  const _SkTextField({
    required this.controller,
    required this.hintText,
    required this.fillColor,
    required this.borderColor,
    required this.hintColor,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF081B4A), width: 1.4),
        ),
      ),
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _SocialCircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
