import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import
import 'package:skudyx/core/theme/app_text_styles.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../core/widgets/sk_primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class Instruction4Screen extends StatelessWidget {
  const Instruction4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [SquareBackButton(onTap: () => context.pop())],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      Text(
                        'Almost Done',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Just a few steps to activate your protection.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 16,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Using your SVG assets from the icons folder
                      const _StepItem(
                        svgPath:
                            'assets/icons/blutooth_icon.svg', // Replace with your bluetooth svg if available
                        title: 'Connect your SkudyX Button',
                      ),
                      const _StepItem(
                        svgPath: 'assets/icons/document_icon.svg',
                        title: 'Add an emergency contact',
                      ),
                      const _StepItem(
                        svgPath: 'assets/icons/person_icon.svg',
                        title: 'Complete your profile setup',
                      ),
                      const _StepItem(
                        svgPath: 'assets/icons/active_icon.svg',
                        title: 'Activate your device',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: SkPrimaryButton(
                text: 'Next',
                onPressed: () async {
                  await context.read<AuthController>().markOnboardingSeen();
                  if (context.mounted) context.go(AppRoutes.device);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String svgPath; // Changed from IconData to String path
  final String title;
  final bool isLast;

  const _StepItem({
    required this.svgPath,
    required this.title,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Container(
                width: 40, // Fixed size for alignment
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  svgPath,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
      ],
    );
  }
}
