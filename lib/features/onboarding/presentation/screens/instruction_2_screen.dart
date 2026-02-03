import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../core/widgets/sk_primary_button.dart';

class Instruction2Screen extends StatelessWidget {
  const Instruction2Screen({super.key});

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
                        'Features',
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
                      _Feature(
                        bg: Color(0xFFFFE5E5),
                        icon: Icons.warning_rounded,
                        iconColor: Color(0xFFE50914),
                        title: 'Alert Emergency Contact',
                        desc: 'Notifies your trusted contact instantly.',
                      ),
                      SizedBox(height: 22),
                      _Feature(
                        bg: Color(0xFFE6F0FF),
                        icon: Icons.location_on_rounded,
                        iconColor: Color(0xFF2563EB),
                        title: 'Share Your Live Location',
                        desc:
                            'Sends your real-time location to help find you\nquickly.',
                      ),
                      SizedBox(height: 22),
                      _Feature(
                        bg: Color(0xFFE7F9EE),
                        icon: Icons.graphic_eq_rounded,
                        iconColor: Color(0xFF16A34A),
                        title: 'Stream Live Audio',
                        desc:
                            'Streams audio from your phone to the support\nteam for real-time assistance.',
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
                onPressed: () => context.push(AppRoutes.instruction3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;

  const _Feature({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
