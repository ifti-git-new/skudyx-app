import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/profile/controllers/identity_verification_controller.dart';

class IdentitySelectScreen extends StatelessWidget {
  const IdentitySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<IdentityVerificationController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Verify your identity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _IdOption(
                title: 'National ID Card',
                icon: Icons.badge_outlined,
                selected: flow.selected == IdType.nid,
                onTap: () {
                  flow.select(IdType.nid);
                  context.push(AppRoutes.identityCapture);
                },
              ),
              const SizedBox(height: 12),
              _IdOption(
                title: 'Passport',
                icon: Icons.public,
                selected: flow.selected == IdType.passport,
                onTap: () {
                  flow.select(IdType.passport);
                  context.push(AppRoutes.identityCapture);
                },
              ),
              const SizedBox(height: 12),
              _IdOption(
                title: 'Driving License',
                icon: Icons.credit_card,
                selected: flow.selected == IdType.driving,
                onTap: () {
                  flow.select(IdType.driving);
                  context.push(AppRoutes.identityCapture);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IdOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  static const _border = Color(0xFFE5E7EB);
  static const _selectedBorder = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _selectedBorder : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0EA5E9)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
