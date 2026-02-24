import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/emergency/presentation/controllers/emergency_contact_controller.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';

class CompleteSetupScreen extends StatelessWidget {
  const CompleteSetupScreen({super.key});

  static const _bg = Color(0xFFF7F8FA);
  static const _border = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AppStatusController>();
    final ec = context.watch<EmergencyContactController>();
    final profile = context.watch<ProfileController>();

    // Completion flags (UI-only mapping for now)
    final subscriptionDone = status.isSubscribed;

    // For now: using deviceArrived as "device step available/started".
    // Later replace with a real "paired device" flag.
    final deviceDone = status.deviceArrived;

    final contactDone = ec.contact != null; // reliable and reactive
    final photoDone =
        false; // TODO: set true after implementing profile photo upload
    final identityDone = profile.identityVerified;

    final items = <_SetupItem>[
      _SetupItem(
        title: 'Subscription plan',
        subtitle: 'Choose a plan to activate SkudyX.',
        done: subscriptionDone,
        onTap: () => context.push(AppRoutes.subscription),
      ),
      _SetupItem(
        title: 'Add a device',
        subtitle: 'Search and connect your SkudyX button.',
        done: deviceDone,
        onTap: () => context.go(AppRoutes.deviceArrived),
      ),
      _SetupItem(
        title: 'Add emergency contact',
        subtitle: 'Add and verify your trusted person.',
        done: contactDone,
        onTap: () {
          final target = contactDone
              ? AppRoutes.emergencyContact
              : AppRoutes.emergencyContactEdit;
          context.push(target);
        },
      ),
      _SetupItem(
        title: 'Upload profile photo',
        subtitle: 'Helps support identify you faster.',
        done: photoDone,
        onTap: () => context.push(AppRoutes.profileEdit),
      ),
      _SetupItem(
        title: 'Identity verification',
        subtitle: 'Verify your identity to complete setup.',
        done: identityDone,
        onTap: () => context.push(AppRoutes.identityIntro),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + title
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Complete Setup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Saturday, Feb 01, 2026',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _SetupCard(item: items[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupItem {
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  const _SetupItem({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });
}

class _SetupCard extends StatelessWidget {
  final _SetupItem item;
  const _SetupCard({required this.item});

  static const _border = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF3F4F6),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            if (item.done)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF16A34A),
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              )
            else
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
