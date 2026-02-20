import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/profile/controllers/identity_verification_controller.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';

class IdentitySuccessScreen extends StatelessWidget {
  const IdentitySuccessScreen({super.key});

  static const _navy = Color(0xFF081B4A);

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileController>();
    final flow = context.read<IdentityVerificationController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7E6),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2DBE2D),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 34),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Congratulation!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your identity is verified successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SizedBox(
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
                  onPressed: () {
                    // ✅ mark verified and update Profile UI
                    profile.setIdentityVerified(true);

                    // reset flow
                    flow.reset();

                    // return to Profile tab
                    context.go(AppRoutes.profile);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
