import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

import '../../../../core/navigation/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_ui_constants.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7E6),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Center(child: Image.asset('assets/images/ok.png')),
            ),
            const SizedBox(height: 18),
            Text('Congratulation!', style: AppTextStyles.h1),
            const SizedBox(height: 10),
            Text(
              "You’re all set! Your registration is complete.",
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AuthUi.subText),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthUi.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () async {
                    // await auth.mockLogin(isNewUser: true);
                    context.push(AppRoutes.instruction1);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
