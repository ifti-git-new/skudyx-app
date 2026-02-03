import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../../../core/theme/app_colors.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context
        .watch<
          AppPrefs
        >(); // prefs is not ChangeNotifier; this won't rebuild automatically

    // Because AppPrefs is not a notifier, we read it once.
    // UI will update after a hot reload, or you can restart.
    // Later we can add a ChangeNotifier "AppStatusController" to rebuild instantly.

    final isSubscribed = prefs.isSubscribed;
    final hasDeliveryDetails = prefs.hasDeliveryDetails;

    if (!isSubscribed) {
      return _NotPurchasedView();
    }

    if (isSubscribed && !hasDeliveryDetails) {
      return _PurchasedNoDeliveryView();
    }

    // Placeholder for later states
    return const Center(
      child: Text('Device Screen (Next states will come here)'),
    );
  }
}

class _NotPurchasedView extends StatelessWidget {
  const _NotPurchasedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 90,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Choose a plan to activate\nSkudyX and receive your\nemergency button.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.subscription),
                    child: const Text(
                      'View Plans',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchasedNoDeliveryView extends StatelessWidget {
  const _PurchasedNoDeliveryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 90,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 22),
                const Text(
                  'We’re ready to ship your\nSkudyX Emergency Button.\nAdd your delivery details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 220,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.deliveryDetails),
                    child: const Text(
                      'Add Delivery Address',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
