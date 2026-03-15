import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/controllers/app_status_controller.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../presentation/controllers/device_session_controller.dart';
import 'device_connected_screen.dart';
import 'device_list_screen.dart';
import 'widgets/device_on_the_way_view.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AppStatusController>();
    final session = context.watch<DeviceSessionController>();

    // ✅ If device arrived -> show connected/list based on session
    if (status.deviceArrived) {
      return session.isConnected
          ? const DeviceConnectedScreen()
          : const DeviceListScreen();
    }

    if (!status.isSubscribed) return const _NotPurchasedView();
    if (!status.hasDeliveryDetails) return const _PurchasedNoDeliveryView();
    return const DeviceOnTheWayView();
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
                Image.asset('assets/images/lock.png', width: 90, height: 90),
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
                    // ✅ Restore real navigation
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
                Image.asset('assets/images/box_ok.png', width: 90, height: 90),
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
                    // ✅ Restore real navigation
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
