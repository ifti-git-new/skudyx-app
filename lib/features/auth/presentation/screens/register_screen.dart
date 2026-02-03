import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../widgets/auth_ui_constants.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Create Account',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
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

                SkTextField(
                  controller: _firstNameCtrl,
                  hintText: 'First name *',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),

                SkTextField(
                  controller: _lastNameCtrl,
                  hintText: 'Last name *',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),

                SkTextField(
                  controller: _emailCtrl,
                  hintText: 'Email *',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                SkTextField(
                  controller: _passCtrl,
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

                const SizedBox(height: 18),

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
                    onPressed: () {
                      // UI-only for now (later call register API then go OTP)
                      context.push(AppRoutes.emailOtp);
                    },
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
                      style: TextStyle(
                        fontSize: 13,
                        color: AuthUi.subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.login),
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

                const SizedBox(height: 26),

                const DividerLabelRow(text: 'Login with'),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!Platform.isIOS)
                      SocialCircleButton(
                        onTap: () {
                          // TODO: Google Sign-in later
                        },
                        child: SvgPicture.asset(
                          'assets/icons/google.svg',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                    if (Platform.isIOS)
                      SocialCircleButton(
                        onTap: () {
                          // TODO: Apple Sign-in later
                        },
                        child: const Icon(
                          Icons.apple,
                          size: 26,
                          color: Colors.black,
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
