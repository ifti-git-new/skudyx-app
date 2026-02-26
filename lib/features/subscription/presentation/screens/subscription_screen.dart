import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/app_prefs.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

enum PlanType { basic, premium }

enum BillingCycle { monthly, yearly }

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _navy = Color(0xFF081B4A);
  static const _subText = Color(0xFF6B7280);

  // FIXED: Initialized to Premium so it matches the left position
  PlanType _plan = PlanType.premium;
  BillingCycle _cycle = BillingCycle.yearly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = context.read<AppPrefs>();
      if (!prefs.subscriptionPromptShown) {
        await prefs.setSubscriptionPromptShown(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Selection logic remains the same, just driven by the new toggle order
    final planData = _plan == PlanType.premium ? _premiumPlan() : _basicPlan();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 90),
                Text(
                  'Pick Your Plan',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1light.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Select how you want SkudyX to help you in an emergency.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: _subText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                // FIXED: Swapped labels and callbacks
                _SegmentedToggle(
                  left: 'Premium',
                  right: 'Basic',
                  selectedLeft: _plan == PlanType.premium,
                  onLeft: () => setState(() => _plan = PlanType.premium),
                  onRight: () => setState(() => _plan = PlanType.basic),
                ),
                const SizedBox(height: 18),
                _PlanCard(
                  title: planData.title,
                  badgeText: planData.badgeText,
                  description: planData.description,
                  features: planData.features,
                  monthlyPrice: planData.monthlyPrice,
                  yearlyPrice: planData.yearlyPrice,
                  yearlyOldPrice: planData.yearlyOldPrice,
                  cycle: _cycle,
                  onCycleChange: (c) => setState(() => _cycle = c),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () async {
                      await context.read<AppStatusController>().setSubscribed(
                        true,
                      );
                      if (context.mounted) {
                        context.push(AppRoutes.deliveryDetails);
                      }
                    },
                    child: Text(
                      'Subscribe',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already a subscriber? ',
                      style: AppTextStyles.caption.copyWith(color: _subText),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Restore',
                        style: AppTextStyles.caption.copyWith(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _PlanModel _basicPlan() => const _PlanModel(
    title: 'Basic Plan',
    badgeText: null,
    description: 'Essential emergency alerts for personal\nsafety.',
    features: [
      'Alerts your emergency contact',
      'Shares your current location',
      'Sends emergency SMS & email',
      'Works without live monitoring',
    ],
    monthlyPrice: '€49.99',
    yearlyOldPrice: '€100.00',
    yearlyPrice: '€499.99',
  );

  _PlanModel _premiumPlan() => const _PlanModel(
    title: 'Premium Plan',
    badgeText: 'Save 20%',
    description:
        'Full emergency assistance with live\nmonitoring and agent support.',
    features: [
      'Dedicated support agent assistance',
      'Emergency case escalation',
      'Real-time location & movement tracking',
      'Live audio streaming from your phone',
      'Coordination with nearby security\nservices',
    ],
    monthlyPrice: '€99.99',
    yearlyOldPrice: '€400.00',
    yearlyPrice: '€799.99',
  );
}

// Data Model and Sub-widgets remain below...
// (Included for completeness as requested)

class _PlanModel {
  final String title;
  final String? badgeText;
  final String description;
  final List<String> features;
  final String monthlyPrice;
  final String yearlyOldPrice;
  final String yearlyPrice;

  const _PlanModel({
    required this.title,
    required this.badgeText,
    required this.description,
    required this.features,
    required this.monthlyPrice,
    required this.yearlyOldPrice,
    required this.yearlyPrice,
  });
}

class _SegmentedToggle extends StatelessWidget {
  static const _border = Color(0xFFE5E7EB);
  static const _accent = Color(0xFF4FD3E6);

  final String left;
  final String right;
  final bool selectedLeft;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _SegmentedToggle({
    required this.left,
    required this.right,
    required this.selectedLeft,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLeft,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedLeft ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  left,
                  style: AppTextStyles.button.copyWith(
                    color: selectedLeft
                        ? Colors.black
                        : const Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onRight,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !selectedLeft ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  right,
                  style: AppTextStyles.button.copyWith(
                    color: !selectedLeft
                        ? Colors.black
                        : const Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  static const _border = Color(0xFFE5E7EB);
  static const _subText = Color(0xFF6B7280);
  static const _check = Color(0xFF0EA5E9);
  static const _recommended = Color(0xFFFFE9A6);

  final String title;
  final String? badgeText;
  final String description;
  final List<String> features;
  final String monthlyPrice;
  final String yearlyOldPrice;
  final String yearlyPrice;
  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onCycleChange;

  const _PlanCard({
    required this.title,
    required this.badgeText,
    required this.description,
    required this.features,
    required this.monthlyPrice,
    required this.yearlyOldPrice,
    required this.yearlyPrice,
    required this.cycle,
    required this.onCycleChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF7DF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF16A34A),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.textfont.copyWith(height: 1.50),
          ),
          const SizedBox(height: 16),
          Text(
            'Features:',
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check, size: 18, color: _check),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: AppTextStyles.textfont.copyWith(
                        fontSize: 14,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: _border),
          _PriceRow(
            left: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: monthlyPrice,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' /Month',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: _subText,
                    ),
                  ),
                ],
              ),
            ),
            selected: cycle == BillingCycle.monthly,
            onTap: () => onCycleChange(BillingCycle.monthly),
          ),
          const Divider(color: _border),
          _PriceRow(
            left: Row(
              children: [
                Text(
                  yearlyOldPrice,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: _subText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  yearlyPrice,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/Year',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: _subText,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _recommended,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Recommended',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            selected: cycle == BillingCycle.yearly,
            onTap: () => onCycleChange(BillingCycle.yearly),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Widget left;
  final bool selected;
  final VoidCallback onTap;

  const _PriceRow({
    required this.left,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: left),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
