import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_controller.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Validation helpers ──────────────────────────────────────────────────────

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  // ── Register action ─────────────────────────────────────────────────────────

  Future<void> _onRegister() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = context.read<AuthController>();

    final success = await controller.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // TODO: Navigate to home / onboarding
      context.push(AppRoutes.emailOtp);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorMsg =
          controller.state.errorMessage ?? 'Registration failed. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Rebuild only when isLoading changes — no full tree rebuild
    final isLoading = context.select<AuthController, bool>(
      (c) => c.state.isLoading,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: AbsorbPointer(
        // Block all taps while loading
        absorbing: isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // ── Title ──────────────────────────────────────────────
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Use your email to create account',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── First Name ─────────────────────────────────────────
                    _buildFormField(
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      hintText: 'First name *',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_lastNameFocus),
                      validator: (v) => _validateRequired(v, 'First name'),
                    ),

                    const SizedBox(height: 14),

                    // ── Last Name ──────────────────────────────────────────
                    _buildFormField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      hintText: 'Last name *',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_emailFocus),
                      validator: (v) => _validateRequired(v, 'Last name'),
                    ),

                    const SizedBox(height: 14),

                    // ── Email ──────────────────────────────────────────────
                    _buildFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hintText: 'Email *',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 14),

                    // ── Password ───────────────────────────────────────────
                    _buildPasswordField(isLoading: isLoading),

                    const SizedBox(height: 28),

                    // ── Submit Button ──────────────────────────────────────
                    _buildSubmitButton(isLoading: isLoading),

                    const SizedBox(height: 22),

                    // ── Login link ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  context.push(AppRoutes.login);
                                  // TODO: Navigate to login screen
                                  // e.g. context.go('/login');
                                },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A2340),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Social divider ─────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFE0E0E0),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'Login with',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFE0E0E0),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Social Buttons ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          onTap: isLoading
                              ? null
                              : () => context
                                    .read<AuthController>()
                                    .signInWithGoogle(),
                          child: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              size: 26,
                              color: Color(0xFFEA4335),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildSocialButton(
                          onTap: isLoading
                              ? null
                              : () => context
                                    .read<AuthController>()
                                    .signInWithApple(),
                          child: const Icon(
                            Icons.apple,
                            size: 24,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ───────────────────────────────────────────────────────────

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
    ValueChanged<String>? onFieldSubmitted,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: _inputDecoration(hintText),
    );
  }

  Widget _buildPasswordField({required bool isLoading}) {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => isLoading ? null : _onRegister(),
      validator: _validatePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: _inputDecoration('Password *').copyWith(
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFFAAAAAA),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : _onRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2340),
          // Keeps the same dark colour while disabled so the spinner is visible
          disabledBackgroundColor: const Color(0xFF1A2340).withOpacity(0.75),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loader'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  key: ValueKey('label'),
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1A2340), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 11.5, color: Color(0xFFB71C1C)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
    );
  }
}
