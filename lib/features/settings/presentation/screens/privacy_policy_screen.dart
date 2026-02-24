import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _bg = Color(0xFFF7F8FA);
  static const _border = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Last updated: January 11, 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionTitle('Information We Collect'),

                  _Card(
                    child: _InfoBlock(
                      title: 'Personal Information',
                      body:
                          'When you create an account, we collect information such as your name, email address, and phone number to provide you with our services.',
                    ),
                  ),

                  SizedBox(height: 12),

                  _Card(
                    child: _InfoBlock(
                      title: 'Usage Data',
                      body:
                          'We automatically collect information about how you interact with our app, including device information, IP address, and usage patterns to improve our services.',
                    ),
                  ),

                  SizedBox(height: 12),

                  _Card(
                    child: _InfoBlock(
                      title: 'Cookies & Tracking',
                      body:
                          'We use cookies and similar technologies to enhance your experience and analyze app performance.',
                    ),
                  ),

                  SizedBox(height: 18),

                  _SectionTitle('How We Use Your Information'),

                  _Card(
                    child: _BulletList(
                      items: [
                        'To provide and maintain our services',
                        'To notify you about changes to our service',
                        'To provide customer support',
                        'To analyze usage and improve our app',
                        'To detect and prevent technical issues',
                        'To send you updates and promotional materials (with your consent)',
                      ],
                    ),
                  ),

                  SizedBox(height: 18),

                  _SectionTitle('Data Security'),

                  _Card(
                    child: _InfoBlock(
                      title: '',
                      body:
                          'We implement industry-standard security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black,
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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

class _InfoBlock extends StatelessWidget {
  final String title;
  final String body;

  const _InfoBlock({required this.title, required this.body});

  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.trim().isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          body,
          style: const TextStyle(fontSize: 13, color: _muted, height: 1.35),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
