import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../core/widgets/sk_primary_button.dart';

class Instruction3Screen extends StatelessWidget {
  const Instruction3Screen({super.key});

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
                        'How SkudyX Works',
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
                      _T(
                        index: 1,
                        title: 'Choose a safety plan',
                        desc: "Pick’ve level your care that fits your life.",
                        isLast: false,
                      ),
                      _T(
                        index: 2,
                        title:
                            'We deliver your SkudyX Emergency Button to\nyour address',
                        desc: 'Sent directly your edified address',
                        isLast: false,
                      ),
                      _T(
                        index: 3,
                        title: 'Press the button during an emergency',
                        desc: 'One-touch activation when your need help.',
                        isLast: false,
                      ),
                      _T(
                        index: 4,
                        title: 'We alert your contact and support team',
                        desc: 'Instant contact with your support and lovends.',
                        isLast: true,
                      ),
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
                onPressed: () => context.push(AppRoutes.instruction4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _T extends StatelessWidget {
  final int index;
  final String title;
  final String desc;
  final bool isLast;
  const _T({
    required this.index,
    required this.title,
    required this.desc,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFF38BDF8);
    return SizedBox(
      height: 88,
      child: Row(
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
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Positioned(
                    top: 24,
                    left: 13,
                    bottom: 0,
                    child: Container(width: 2, color: c),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
