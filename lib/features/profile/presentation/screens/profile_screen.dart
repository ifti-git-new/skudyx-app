import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_controller.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _bg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileController>();
    final auth = context.read<AuthController>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            children: [
              // Header row: Profile + edit icon
              Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      context.push(AppRoutes.profileEdit);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Avatar + warning badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 2,
                      ),
                      image: const DecorationImage(
                        fit: BoxFit.cover,
                        // Replace with real profile image later
                        image: NetworkImage('https://i.pravatar.cc/300'),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: 6,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _border),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                p.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Profile Setup: ',
                      style: TextStyle(color: _muted),
                    ),
                    TextSpan(
                      text: '${p.profilePercent}%',
                      style: const TextStyle(color: Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Additional Information card
              _Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _InfoRow(
                        label: 'Phone Number',
                        value: p.phone,
                        badge: _Pill(
                          text: p.phoneVerified ? 'Verified' : 'Not verified',
                          bg: p.phoneVerified
                              ? const Color(0xFFDFF7DF)
                              : const Color(0xFFFFE9A6),
                          fg: p.phoneVerified
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF92400E),
                        ),
                        underline: true,
                      ),

                      const SizedBox(height: 14),

                      _InfoRow(
                        label: 'Email',
                        value: p.email,
                        badge: _Pill(
                          text: p.emailVerified ? 'Verified' : 'Not verified',
                          bg: p.emailVerified
                              ? const Color(0xFFDFF7DF)
                              : const Color(0xFFFFE9A6),
                          fg: p.emailVerified
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF92400E),
                        ),
                        underline: true,
                      ),

                      const SizedBox(height: 14),

                      _InfoRow(
                        label: 'Address',
                        value: p.addressLine1.isEmpty ? '—' : p.addressDisplay,
                        badge: null,
                        underline: false,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Identity Verification item
              _ListTileCard(
                leadingBg: const Color(0xFFEFF6FF),
                leadingIcon: Icons.person_outline,
                leadingIconColor: const Color(0xFF1D4ED8),
                title: 'Identity Verification',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Pill(
                      text: p.identityVerified ? 'Verified' : 'Not verified',
                      bg: p.identityVerified
                          ? const Color(0xFFDFF7DF)
                          : const Color(0xFFFFE9A6),
                      fg: p.identityVerified
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF92400E),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right, color: _muted),
                  ],
                ),
                onTap: () => context.push(AppRoutes.identityIntro),
              ),

              const SizedBox(height: 12),

              // Logout item
              _ListTileCard(
                leadingBg: const Color(0xFFFFE4E6),
                leadingIcon: Icons.logout,
                leadingIconColor: const Color(0xFFDC2626),
                title: 'Log Out',
                titleColor: const Color(0xFFDC2626),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFDC2626),
                ),
                onTap: () async {
                  await auth.logout();

                  // Route to login (leave ShellRoute)
                  if (context.mounted) {
                    GoRouter.of(context).go(AppRoutes.login);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.badge,
    required this.underline,
  });

  final String label;
  final String value;
  final Widget? badge;
  final bool underline;

  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(value, style: valueStyle),
            ],
          ),
        ),
        ?badge,
      ],
    );
  }
}

class _ListTileCard extends StatelessWidget {
  const _ListTileCard({
    required this.leadingBg,
    required this.leadingIcon,
    required this.leadingIconColor,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.titleColor,
  });

  final Color leadingBg;
  final IconData leadingIcon;
  final Color leadingIconColor;
  final String title;
  final Color? titleColor;
  final Widget trailing;
  final VoidCallback onTap;

  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: leadingBg,
                  border: Border.all(color: _border),
                ),
                child: Icon(leadingIcon, color: leadingIconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: titleColor ?? Colors.black,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
