import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/features/delivery/presentation/controller/delivery_details_controller.dart';
import 'package:skudyx/features/device/presentation/device_arrived_screen.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';

import '../../../../core/controllers/app_status_controller.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../presentation/controllers/device_session_controller.dart';
import 'device_connected_screen.dart';
import 'device_list_screen.dart';
import '../../../delivery/presentation/screens/device_on_the_way_view.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the fresh profile on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadProfile();
     // _handleConditionalAPIcalls();
    });
  }

  // void _handleConditionalAPIcalls() {
  //   final profile = context.read<ProfileController>().profileModel;
  //   if (profile == null) return;
  //   final data = profile.data;
  //   final shouldLoadDelivery =
  //       data?.subscriptionPlan != 'N/A' &&
  //       data?.subscriptionStatus == 'Active' &&
  //       data?.orderStatus == 'Placed' &&
  //       data?.bleDeviceId == null;
  //   if (shouldLoadDelivery) {
  //     context.read<DeviceDeliveryController>().fetchMyOrder();
  //   }
  // }

 @override
Widget build(BuildContext context) {
  final profileCtrl = context.watch<ProfileController>();
  final profileData = profileCtrl.profileModel;

  // 1. Loading
  if (profileCtrl.isLoading) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              "Preparing your device dashboard...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Failed to load
  if (profileData == null) {
    return _profileErrorWidget(profileCtrl);
  }

  // 3. Profile loaded — check subscription/device state
  final subscriptionPlan = profileData.data!.subscriptionPlan;
  final subscriptionStatus = profileData.data!.subscriptionStatus;
  final bleDeviceID = profileData.data!.bleDeviceId;
  final orderStatus = profileData.data!.orderStatus;

  if (subscriptionPlan == 'N/A') {
    return _NotPurchasedView();
  }

  if (subscriptionStatus == 'Active' && bleDeviceID == null && orderStatus == null) {
    return _PurchasedNoDeliveryView();
  }

  if (subscriptionStatus == 'Active' && orderStatus == 'Placed' && bleDeviceID == null) {
    return DeviceArrivedScreen();
    //return DeviceOnTheWayView();
  }
   if (subscriptionStatus == 'Active' && orderStatus == 'Confirmed' && bleDeviceID == null) {
    return DeviceArrivedScreen();
    //return DeviceOnTheWayView();
  }

  if (subscriptionStatus == 'Active' && orderStatus == 'Shipped' && bleDeviceID == null) {
    return DeviceArrivedScreen();
  }

  return DeviceConnectedScreen(bleDeviceID: bleDeviceID,);
}

  Scaffold _profileErrorWidget(ProfileController profileCtrl) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load your profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Something went wrong while fetching your data.\nPlease try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => profileCtrl
                      .loadProfile(), // 👈 replace with your actual refresh method
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
                    onPressed: () => context.go(AppRoutes.deliveryDetails),
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
