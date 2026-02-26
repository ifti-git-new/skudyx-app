import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/sk_primary_button.dart';

class Instruction1Screen extends StatelessWidget {
  const Instruction1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 120),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/instruction_icon1.png"),
                const SizedBox(width: 14),
                const Icon(Icons.arrow_forward, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 14),
                Image.asset("assets/images/instruction_icon2.png"),
                const SizedBox(width: 14),
                const Icon(Icons.arrow_forward, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 14),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset("assets/images/instruction_icon3.png"),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF16A34A),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Get Help When\nNeed It Most',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'SkudyX helps you get help fast during emergencies — from people you trust and our dedicated support team.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SkPrimaryButton(
                text: 'Continue',
                onPressed: () => context.push(AppRoutes.instruction2),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
