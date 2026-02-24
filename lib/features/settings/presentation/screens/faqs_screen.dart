import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  static const _bg = Color(0xFFF7F8FA);

  final List<_FaqItem> _items = const [
    _FaqItem(
      q: 'What is this app used for?',
      a: 'This app helps you manage your tasks, access features easily, and enjoy a smooth, user-friendly experience—all in one place.',
    ),
    _FaqItem(
      q: 'How do I create an account?',
      a: 'Go to the Login screen and tap Create Account, then complete the OTP verification.',
    ),
    _FaqItem(
      q: 'Is the app free to use?',
      a: 'Some features may require an active subscription plan.',
    ),
    _FaqItem(
      q: 'I forgot my password. What should I do?',
      a: 'Use the “Forgot Password” option on the Login screen to reset your password.',
    ),
    _FaqItem(
      q: 'How do I create an account?',
      a: 'Use the Create Account flow from the Login screen.',
    ),
    _FaqItem(
      q: 'How do I create an account?',
      a: 'Use the Create Account flow from the Login screen.',
    ),
    _FaqItem(
      q: 'Is my data safe?',
      a: 'We follow standard security practices and only access sensitive data when required for safety features.',
    ),
    _FaqItem(
      q: 'Can I use the app on multiple devices?',
      a: 'You can sign in on multiple devices, but device pairing may be limited by your plan and security settings.',
    ),
    _FaqItem(
      q: 'How do I update the app?',
      a: 'Update SkudyX from the App Store / Google Play Store.',
    ),
  ];

  int? _expandedIndex = 0; // first open like your screenshot

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
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We're here to help you get the most out of our app",
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
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = _items[i];
                final expanded = _expandedIndex == i;

                return _FaqCard(
                  question: item.q,
                  answer: item.a,
                  expanded: expanded,
                  onTap: () {
                    setState(() {
                      _expandedIndex = expanded ? null : i;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqCard({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  static const _border = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0, // chevron up/down
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _muted,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    answer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _muted,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
