import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                _Circle(
                  bg: const Color(0xFFFFE5E5),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE50914),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.arrow_forward, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 14),
                _Circle(
                  bg: const Color(0xFFE6F0FF),
                  child: const Icon(
                    Icons.phone_iphone,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.arrow_forward, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 14),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _Circle(
                      bg: const Color(0xFFE7F9EE),
                      child: const Icon(
                        Icons.support_agent,
                        color: Color(0xFF16A34A),
                        size: 30,
                      ),
                    ),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Get Help When\nNeed It Most',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'SkudyX helps you get help fast during\nemergencies — from people you trust and our\ndedicated support team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
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

class _Circle extends StatelessWidget {
  final Color bg;
  final Widget child;
  const _Circle({required this.bg, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Center(child: child),
    );
  }
}
