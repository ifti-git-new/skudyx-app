import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

import '../../../../core/navigation/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_ui_constants.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final authWatch = context.watch<AuthController>();
    final auth = context.read<AuthController>();
    final isLoading = authWatch.state.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 110),
                Text('Login', style: AppTextStyles.h1),
                const SizedBox(height: 10),
                Text(
                  'Enter your email and password to log in',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 34),

                SkTextField(
                  controller: _emailCtrl,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                SkTextField(
                  controller: _passCtrl,
                  hintText: 'Password',
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

                const SizedBox(height: 14),
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AuthUi.fieldBorder),
                            ),
                            child: _rememberMe
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: AuthUi.navy,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text('Remember me', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        'Forgot Password ?',
                        style: AppTextStyles.caption.copyWith(
                          color: AuthUi.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
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
                    onPressed: isLoading
                        ? null
                        : () async {
                            final ok = await auth.login(
                              email: _emailCtrl.text,
                              password: _passCtrl.text,
                              rememberMe: _rememberMe,
                            );

                            if (!context.mounted) return;

                            if (ok) {
                              // TEMPORARY: mark onboarding as seen and go directly to DeviceConnectedScreen
                              //await auth.markOnboardingSeen();
                              if (context.mounted) {
                                context.go(AppRoutes.device);
                              }
                            } else {
                              final msg =
                                  context
                                      .read<AuthController>()
                                      .state
                                      .errorMessage ??
                                  'Login failed';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(msg)));
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Login',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don’t have an account?  ",
                      style: AppTextStyles.caption.copyWith(
                        color: AuthUi.subText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: const Text(
                        'Create Account',
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
                Row(
                  children: const [
                    Expanded(
                      child: Divider(color: AuthUi.fieldBorder, thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Login with',
                        style: TextStyle(
                          fontSize: 13,
                          color: AuthUi.subText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AuthUi.fieldBorder, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                InkWell(
                  onTap: () async {
                    if (Platform.isIOS) {
                      await auth.signInWithApple();
                    } else {
                      await auth.signInWithGoogle();
                    }
                    if (context.mounted) context.go(AppRoutes.device);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AuthUi.fieldBorder),
                    ),
                    child: Center(
                      child: Platform.isIOS
                          ? const Icon(
                              Icons.apple,
                              size: 26,
                              color: Colors.black,
                            )
                          : SvgPicture.asset(
                              'assets/icons/google.svg',
                              width: 22,
                              height: 22,
                            ),
                    ),
                  ),
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
