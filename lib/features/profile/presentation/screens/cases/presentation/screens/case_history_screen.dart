import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/theme/app_colors.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

class CaseHistoryScreen extends StatelessWidget {
  const CaseHistoryScreen({super.key});

  static const _bg = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    // UI-only mock data
    final items = List.generate(
      8,
      (i) => _CaseItem(
        id: '#C1234567',
        dateTime: i == 0 ? '01 Jan, 2026 2:44 PM' : '03 Jan, 2026 2:44 PM',
      ),
    );

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Back chip + title (like your design)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
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
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Case History',
                            style: AppTextStyles.h2light.copyWith(
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
            ),

            const SizedBox(height: 14),

            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return _CaseCard(
                    id: item.id,
                    dateTime: item.dateTime,
                    onTap: () {
                      // go to details with param
                      final encoded = Uri.encodeComponent(item.id);
                      context.push('/settings/case-history/$encoded');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseItem {
  final String id;
  final String dateTime;
  const _CaseItem({required this.id, required this.dateTime});
}

class _CaseCard extends StatelessWidget {
  final String id;
  final String dateTime;
  final VoidCallback onTap;

  const _CaseCard({
    required this.id,
    required this.dateTime,
    required this.onTap,
  });

  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                color: AppColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id, style: AppTextStyles.h2light.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    dateTime,
                    style: AppTextStyles.caption.copyWith(color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
