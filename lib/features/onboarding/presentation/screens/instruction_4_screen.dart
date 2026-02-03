import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../core/widgets/sk_primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class Instruction4Screen extends StatelessWidget {
  const Instruction4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 22),
                      Text(
                        'Get Started Checklist',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Lorem ipsum dolor sit amet adipiscing elit.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: 22),
                      _C(text: 'Add safety contact', isLast: false),
                      SizedBox(height: 12),
                      _C(text: 'Verify details', isLast: false),
                      SizedBox(height: 12),
                      _C(text: 'Activate device', isLast: false),
                      SizedBox(height: 12),
                      _C(text: 'Add safety contact', isLast: true),
                      SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: SkPrimaryButton(
                text: 'Next',
                onPressed: () async {
                  await context.read<AuthController>().markOnboardingSeen();

                  // OLD:
                  // context.push(AppRoutes.subscription);

                  // NEW: go to device; router decides if subscription is needed once
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

class _C extends StatelessWidget {
  final String text;
  final bool isLast;
  const _C({required this.text, required this.isLast});

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFF38BDF8);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Stack(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              if (!isLast)
                Positioned(
                  top: 24,
                  left: 13,
                  bottom: -18,
                  child: Container(width: 2, color: c),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
