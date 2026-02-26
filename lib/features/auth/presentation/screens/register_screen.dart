import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG support

import '../../../../core/navigation/app_routes.dart';
import '../widgets/auth_ui_constants.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if platform is iOS for conditional Apple button display
    final bool isIos = Platform.isIOS;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 80),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use your email to create account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AuthUi.subText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 34),

                SkTextField(controller: _firstName, hintText: 'First name *'),
                const SizedBox(height: 16),
                SkTextField(controller: _lastName, hintText: 'Last name *'),
                const SizedBox(height: 16),
                SkTextField(
                  controller: _email,
                  hintText: 'Email *',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                SkTextField(
                  controller: _pass,
                  hintText: 'Password *',
                  obscureText: _obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AuthUi.hint,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                    onPressed: () => context.push(AppRoutes.emailOtp),
                    child: const Text(
                      'Create Account',
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
                      "Already have an account?  ",
                      style: TextStyle(fontSize: 13, color: AuthUi.subText),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 13,
                          color: AuthUi.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // --- LOGIN WITH SECTION ---
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Login with',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      svgPath: 'assets/icons/google.svg',
                      onTap: () {
                        // Action for Google Sign-In
                      },
                    ),
                    if (isIos) ...[
                      const SizedBox(width: 20),
                      _SocialButton(
                        svgPath: 'assets/icons/apple.svg',
                        onTap: () {
                          // Action for Apple Sign-In
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String svgPath;
  final VoidCallback onTap;

  const _SocialButton({required this.svgPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF3F4F6)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SvgPicture.asset(
          svgPath,
          // Ensuring icons fit well within the 54x54 container
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
