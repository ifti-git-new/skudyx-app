import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class Instruction1Screen extends StatelessWidget {
  const Instruction1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Instruction 1 (Placeholder)')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => auth.markOnboardingSeen(),
          child: const Text('Finish Onboarding (Mock)'),
        ),
      ),
    );
  }
}
