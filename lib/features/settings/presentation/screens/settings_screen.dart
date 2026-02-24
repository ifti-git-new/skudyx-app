import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/settings/presentation/delete_account/delete_account_flow.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _bg = Color(0xFFF7F8FA);
  static const _border = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              _Card(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.history_rounded,
                      title: 'Case History',
                      onTap: () => context.push(AppRoutes.settingsCaseHistory),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Complete Setup',
                      onTap: () =>
                          context.push(AppRoutes.settingsCompleteSetup),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.credit_card_rounded,
                      title: 'Subscription',
                      onTap: () => context.push(AppRoutes.subscription),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      onTap: () =>
                          context.push(AppRoutes.settingsNotifications),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.headphones_rounded,
                      title: 'Help & Support',
                      onTap: () => context.push(AppRoutes.settingsHelpSupport),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: 'FAQs',
                      onTap: () => context.push(AppRoutes.settingsFaqs),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      onTap: () =>
                          context.push(AppRoutes.settingsPrivacyPolicy),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () => context.push(AppRoutes.settingsTerms),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete Account',
                      isDestructive: true,
                      onTap: () async {
                        await DeleteAccountFlow.start(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: _border);
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive ? const Color(0xFFDC2626) : Colors.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF3F4F6),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }
}
