import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const _bg = Color(0xFFF7F8FA);
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
                Text(
                  'Terms & Conditions',
                  style: AppTextStyles.h2light.copyWith(
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: January 11, 2026',
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 13,
                    color: Colors.white70,
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
                children: [
                  _SectionTitle('Acceptance of Terms'),
                  _Card(
                    child: _Paragraph(
                      "By downloading, installing, or using this app, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree, please do not use our app.",
                    ),
                  ),
                  SizedBox(height: 18),

                  _SectionTitle('License to Use'),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Paragraph(
                          "We grant you a limited, non-exclusive, non-transferable license to use the app for personal, non-commercial purposes, subject to these terms.",
                        ),
                        SizedBox(height: 14),
                        Text(
                          "You agree NOT to:",
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        _Bullet(
                          text:
                              "Modify, reverse engineer, or decompile the app",
                        ),
                        _Bullet(
                          text:
                              "Use the app for any illegal or unauthorized purpose",
                        ),
                        _Bullet(
                          text:
                              "Attempt to gain unauthorized access to our systems",
                        ),
                        _Bullet(text: "Remove or alter any copyright notices"),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),

                  _SectionTitle('User Accounts'),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Paragraph(
                          "To access certain features, you may need to create an account. You are responsible for:",
                        ),
                        SizedBox(height: 10),
                        _Bullet(
                          text:
                              "Maintaining the confidentiality of your account credentials",
                        ),
                        _Bullet(
                          text: "All activities that occur under your account",
                        ),
                        _Bullet(
                          text:
                              "Notifying us immediately of any unauthorized use",
                        ),
                        _Bullet(
                          text: "Providing accurate and up-to-date information",
                        ),
                      ],
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
        style: AppTextStyles.subtitle.copyWith(
          fontSize: 16,
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

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.subtitle.copyWith(
        fontSize: 13,
        color: Color(0xFF6B7280),
        height: 1.35,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  static const _bullet = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: _bullet),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.subtitle.copyWith(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
