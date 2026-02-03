import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login (Placeholder)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => auth.mockLogin(isNewUser: true),
              child: const Text('Mock Login (New User)'),
            ),
            ElevatedButton(
              onPressed: () => auth.mockLogin(isNewUser: false),
              child: const Text('Mock Login (Existing User)'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text('Create Account'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.forgotPassword),
              child: const Text('Forgot Password'),
            ),
          ],
        ),
      ),
    );
  }
}
