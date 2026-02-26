import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/navigation/app_routes.dart';

class IdentityIntroScreen extends StatelessWidget {
  const IdentityIntroScreen({super.key});

  static const _navy = Color(0xFF081B4A);
  static const _sub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: 54,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF16A34A),
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Verify your identity',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This helps us ensure the safety and reliability\nof emergency services.',
                style: TextStyle(fontSize: 15, color: _sub, height: 1.35),
              ),

              const SizedBox(height: 22),
              const Text(
                'We will ask you to scan:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),

              _InfoCard(
                icon: Icons.badge_outlined,
                text: 'A valid government-issued ID',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.verified_user_outlined,
                text:
                    'Your data will be handled securely and used only for\nverification',
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.identitySelect),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

  static const _border = Color(0xFFE5E7EB);
  static const _sub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: _sub, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
