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

  /// ✅ Fixed Navigation:
  /// Prevents "Nothing to pop" error and routes to Device Screen (NotPurchasedView)
  void _onCancelPressed() {
    final status = context.read<AppStatusController>();

    // If not subscribed, we want them back on the Device tab (showing Lock screen)
    if (!status.isSubscribed) {
      context.go(AppRoutes.device);
    } else {
      // If they ARE subscribed, try to pop back to where they came from
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.device);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planData = _plan == PlanType.premium ? _premiumPlan() : _basicPlan();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Cancel Button and Close Icon
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: _onCancelPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cancel',
                        style: AppTextStyles.button.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Pick Your Plan',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select how you want SkudyX to help you in an emergency.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: _subText,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Toggle for Premium / Basic
                    _SegmentedToggle(
                      left: 'Premium',
                      right: 'Basic',
                      selectedLeft: _plan == PlanType.premium,
                      onLeft: () => setState(() => _plan = PlanType.premium),
                      onRight: () => setState(() => _plan = PlanType.basic),
                    ),

                    const SizedBox(height: 24),

                    // Subscription Card
                    _PlanCard(
                      title: planData.title,
                      badgeText: planData.badgeText,
                      description: planData.description,
                      features: planData.features,
                      monthlyPrice: planData.monthlyPrice,
                      yearlyOldPrice: planData.yearlyOldPrice,
                      yearlyPrice: planData.yearlyPrice,
                      cycle: _cycle,
                      onCycleChange: (c) => setState(() => _cycle = c),
                    ),

                    const SizedBox(height: 32),

                    // Subscribe Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                          await context
                              .read<AppStatusController>()
                              .setSubscribed(true);
                          if (context.mounted) {
                            context.push(AppRoutes.deliveryDetails);
                          }
                        },
                        child: Text(
                          'Subscribe',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Restore Purchases
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already a subscriber? ',
                          style: AppTextStyles.caption.copyWith(
                            color: _subText,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Restore',
                            style: AppTextStyles.caption.copyWith(
                              color: _navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _PlanModel _basicPlan() => const _PlanModel(
    title: 'Basic Plan',
    badgeText: null,
    description: 'Essential emergency alerts for personal safety.',
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
        'Full emergency assistance with live monitoring and agent support.',
    features: [
      'Dedicated support agent assistance',
      'Emergency case escalation',
      'Real-time location & movement tracking',
      'Live audio streaming from your phone',
      'Coordination with nearby security services',
    ],
    monthlyPrice: '€99.99',
    yearlyOldPrice: '€400.00',
    yearlyPrice: '€799.99',
  );
}

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
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
      ),
      child: Row(
        children: [
          _ToggleItem(label: left, isSelected: selectedLeft, onTap: onLeft),
          _ToggleItem(label: right, isSelected: !selectedLeft, onTap: onRight),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4FD3E6) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : const Color(0xFF6B7280),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
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
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 20),
          const Text(
            'Features:',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Color(0xFF4FD3E6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          _PriceOption(
            price: monthlyPrice,
            period: '/Month',
            isSelected: cycle == BillingCycle.monthly,
            onTap: () => onCycleChange(BillingCycle.monthly),
          ),
          const Divider(height: 16),
          _PriceOption(
            price: yearlyPrice,
            oldPrice: yearlyOldPrice,
            period: '/Year',
            isSelected: cycle == BillingCycle.yearly,
            isRecommended: true,
            onTap: () => onCycleChange(BillingCycle.yearly),
          ),
        ],
      ),
    );
  }
}

class _PriceOption extends StatelessWidget {
  final String price;
  final String? oldPrice;
  final String period;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PriceOption({
    required this.price,
    this.oldPrice,
    required this.period,
    required this.isSelected,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (oldPrice != null) ...[
              Text(
                oldPrice!,
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              price,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(period, style: const TextStyle(color: Color(0xFF6B7280))),
            const Spacer(),
            if (isRecommended)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9A6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF4FD3E6) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
