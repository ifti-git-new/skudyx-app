import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';
import 'package:skudyx/features/subscription/data/remote/subscription_api.dart';

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
  bool _isLoading = false;

  // ✅ Responsive helpers
  late double _screenWidth;
  late bool _isSmallScreen;
  late double _horizontalPadding;
  late double _titleFontSize;
  late double _bodyFontSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateResponsiveValues();
  }

  void _updateResponsiveValues() {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _isSmallScreen = _screenWidth < 360;
    _horizontalPadding = _screenWidth < 375 ? 16.0 : 22.0;
    _titleFontSize = _isSmallScreen ? 28.0 : 32.0;
    _bodyFontSize = _isSmallScreen ? 14.0 : 16.0;
  }

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

  void _onCancelPressed() {
    
    final status = context.read<AppStatusController>();
    context.read<ProfileController>().loadProfile();
    if (!status.isSubscribed) {
      
      context.go(AppRoutes.device);
    } else {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        
        context.go(AppRoutes.device);
      }
    }
  }

  bool _isAlreadySubscribed(String? subscriptionPlan) {
    if (subscriptionPlan == null || subscriptionPlan == 'N/A') return false;
    switch (_plan) {
      case PlanType.premium:
        return subscriptionPlan == 'Premium';
      case PlanType.basic:
        return subscriptionPlan == 'Basic';
    }
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    try {
      final planName = _plan == PlanType.premium ? 'Premium' : 'Basic';

      await context.read<AppStatusController>().subscribeWithApi(
        plan: planName,
      );

      final profileCtrl = context.read<ProfileController>();
      final profileData = profileCtrl.profileModel;
      if (profileData != null) {
        final orderStatus = profileData.data?.orderStatus;
        if (orderStatus != null) {
          return;
        } else {
          if (mounted) {
            context.push(AppRoutes.deliveryDetails);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('DioException [bad response]: ', ''),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateResponsiveValues();
    final planData = _plan == PlanType.premium ? _premiumPlan() : _basicPlan();
    final status = context.watch<AppStatusController>();
    final subscriptionPlan = status.subscriptionPlan ?? 'Unknown';

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: _horizontalPadding,
                    top: _isSmallScreen ? 8 : 12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: _isLoading ? null : _onCancelPressed,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: _isSmallScreen ? 20 : 22,
                                color: _isLoading ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.button.copyWith(
                                fontSize: _isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: _isLoading ? Colors.grey : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                      vertical: _isSmallScreen ? 8 : 0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _screenWidth > 600 ? 500 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: _isSmallScreen ? 16 : 24),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Pick Your Plan',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h1.copyWith(
                                fontSize: _titleFontSize,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: _isSmallScreen ? 8 : 12),
                          Text(
                            'Select how you want SkudyX to help you in an emergency.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                              color: _subText,
                              fontSize: _bodyFontSize,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: _isSmallScreen ? 20 : 28),
                          _SegmentedToggle(
                            left: 'Premium',
                            right: 'Basic',
                            selectedLeft: _plan == PlanType.premium,
                            onLeft: _isLoading
                                ? () {}
                                : () =>
                                      setState(() => _plan = PlanType.premium),
                            onRight: _isLoading
                                ? () {}
                                : () => setState(() => _plan = PlanType.basic),
                            screenWidth: _screenWidth,
                            isSmallScreen: _isSmallScreen,
                          ),
                          SizedBox(height: _isSmallScreen ? 16 : 24),
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
                            screenWidth: _screenWidth,
                            isSmallScreen: _isSmallScreen,
                          ),
                          SizedBox(height: _isSmallScreen ? 24 : 32),

                          Builder(
                            builder: (context) {
                              final alreadySubscribed = _isAlreadySubscribed(
                                status
                                    .subscriptionPlan, // ✅ can now be null or 'N/A'
                              );
                              final isDisabled =
                                  _isLoading || alreadySubscribed;
                              return SizedBox(
                                width: double.infinity,
                                height: _isSmallScreen ? 50 : 56,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: _screenWidth > 600
                                        ? 400
                                        : double.infinity,
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isLoading
                                          ? Colors.grey
                                          : _navy,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          _isSmallScreen ? 25 : 50,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _isSmallScreen ? 12 : 24,
                                      ),
                                    ),
                                    onPressed: isDisabled
                                        ? null
                                        : _handleSubscribe,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              alreadySubscribed
                                                  ? 'Already Subscribed'
                                                  : 'Subscribe',
                                              style: AppTextStyles.button
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontSize: _isSmallScreen
                                                        ? 16
                                                        : 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: _isSmallScreen ? 12 : 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Already a subscriber? ',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(
                                    color: _subText,
                                    fontSize: _isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Restore',
                                  style: AppTextStyles.caption.copyWith(
                                    color: _navy,
                                    fontSize: _isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: _isSmallScreen ? 24 : 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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

// ✅ RESPONSIVE SEGMENTED TOGGLE
class _SegmentedToggle extends StatelessWidget {
  final String left;
  final String right;
  final bool selectedLeft;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final double screenWidth;
  final bool isSmallScreen;
  const _SegmentedToggle({
    required this.left,
    required this.right,
    required this.selectedLeft,
    required this.onLeft,
    required this.onRight,
    required this.screenWidth,
    required this.isSmallScreen,
  });
  @override
  Widget build(BuildContext context) {
    final toggleWidth = screenWidth < 375
        ? screenWidth * 0.85
        : (screenWidth > 600 ? 300.0 : 260.0);
    return Center(
      child: Container(
        width: toggleWidth,
        height: isSmallScreen ? 42 : 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(999),
          color: Colors.white,
        ),
        child: Row(
          children: [
            _ToggleItem(
              label: left,
              isSelected: selectedLeft,
              onTap: onLeft,
              isSmallScreen: isSmallScreen,
            ),
            _ToggleItem(
              label: right,
              isSelected: !selectedLeft,
              onTap: onRight,
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSmallScreen;
  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isSmallScreen,
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
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 8,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF6B7280),
                fontSize: isSmallScreen ? 13 : 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
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
  final double screenWidth;
  final bool isSmallScreen;
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
    required this.screenWidth,
    required this.isSmallScreen,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF7DF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          color: const Color(0xFF16A34A),
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            description,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: isSmallScreen ? 12 : 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: isSmallScreen ? 14 : 20),
          Text(
            'Features:',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          ...features.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: isSmallScreen ? 16 : 20,
                    color: const Color(0xFF4FD3E6),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: isSmallScreen ? 24 : 32),
          _PriceOption(
            price: monthlyPrice,
            period: '/Month',
            isSelected: cycle == BillingCycle.monthly,
            onTap: () => onCycleChange(BillingCycle.monthly),
            isSmallScreen: isSmallScreen,
          ),
          Divider(height: isSmallScreen ? 12 : 16),
          _PriceOption(
            price: yearlyPrice,
            period: '/Year',
            isSelected: cycle == BillingCycle.yearly,
            onTap: () => onCycleChange(BillingCycle.yearly),
            isSmallScreen: isSmallScreen,
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
  final bool isSmallScreen;
  const _PriceOption({
    required this.price,
    this.oldPrice,
    required this.period,
    required this.isSelected,
    this.isRecommended = false,
    required this.onTap,
    required this.isSmallScreen,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (oldPrice != null) ...[
                    Flexible(
                      child: Text(
                        oldPrice!,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 8),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        price,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      period,
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF4FD3E6) : Colors.grey,
              size: isSmallScreen ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }
}
