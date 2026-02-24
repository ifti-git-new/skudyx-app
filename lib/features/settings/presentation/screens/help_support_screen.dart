import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _cardBorder = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  // Replace later with your real endpoints/emails
  static const _supportEmail = 'support@yourapp.com';
  static const _helpCenterUrl = 'https://example.com/help';

  Future<void> _openEmail(
    BuildContext context, {
    required String to,
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {'subject': subject, 'body': body},
    );

    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open email app.')),
        );
      }
      return;
    }
    await launchUrl(uri);
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open link.')));
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 18,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6CA8FF), Color(0xFF2F78FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Need more assistance? We're here for you!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              children: [
                _SupportCard(
                  iconBg: const Color(0xFFE8F1FF),
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF2F78FF),
                  title: 'Contact Support',
                  subtitle:
                      'Email us at:  $_supportEmail\nResponse time: Within 24–48 hours',
                  trailingText: null,
                  onTap: () => context.push(AppRoutes.settingsContactSupport),
                ),
                const SizedBox(height: 14),

                _SupportCard(
                  iconBg: const Color(0xFFE7F9EE),
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Help Center',
                  subtitle:
                      'Visit our Help Center for guides,\ntips, and tutorials.',
                  trailingText: 'Visit Help Center →',
                  onTap: () => _openLink(context, _helpCenterUrl),
                ),
                const SizedBox(height: 14),

                _SupportCard(
                  iconBg: const Color(0xFFFFE4E6),
                  icon: Icons.bug_report_outlined,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Report a Problem',
                  subtitle: 'Found a bug or issue?\nShare details with us.',
                  trailingText: null,
                  onTap: () => _openEmail(
                    context,
                    to: _supportEmail,
                    subject: 'SkudyX Bug Report',
                    body:
                        'Steps to reproduce:\n1)\n2)\n\nExpected result:\n\nActual result:\n\n---\n(User ID / Device info will be added later)',
                  ),
                ),
                const SizedBox(height: 14),

                _SupportCard(
                  iconBg: const Color(0xFFFFF7D6),
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Feedback & Suggestions',
                  subtitle:
                      "We'd love to hear from you! Send\nyour ideas and feedback to help\nimprove the app.",
                  trailingText: null,
                  onTap: () => _openEmail(
                    context,
                    to: _supportEmail,
                    subject: 'SkudyX Feedback',
                    body:
                        'My feedback:\n\n---\n(User ID / Device info will be added later)',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  static const _cardBorder = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  const _SupportCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _muted,
                      height: 1.25,
                    ),
                  ),
                  if (trailingText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      trailingText!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
