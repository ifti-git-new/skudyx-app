import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';

class DeviceArrivedScreen extends StatelessWidget {
  const DeviceArrivedScreen({super.key});

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
                // Blue bluetooth circle with double ring effect
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0B74FF),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0B74FF),
                      ),
                      child: const Icon(
                        Icons.bluetooth,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  "Your device has arrived. Let’s\nconnect it to your phone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    // onPressed: () {
                    //   // TODO later: go to BLE scan screen
                    //   // context.push(AppRoutes.deviceSearch);
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text('Search for Device (TODO)'),
                    //     ),
                    //   );
                    // },
                    onPressed: () async {
                      // Android needs runtime permissions for BLE scan/connect
                      if (Platform.isAndroid) {
                        final scan = await Permission.bluetoothScan.request();
                        final connect = await Permission.bluetoothConnect
                            .request();

                        // On some Android versions, location may still be required for BLE scanning
                        // (safe to request; you can remove later if not needed)
                        final location = await Permission.locationWhenInUse
                            .request();

                        final ok =
                            scan.isGranted &&
                            connect.isGranted &&
                            location.isGranted;
                        if (!ok) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bluetooth permissions are required to search for devices.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // iOS will prompt automatically when BLE is accessed; permission_handler isn't required there.
                      if (context.mounted)
                        context.push(AppRoutes.deviceSearching);
                    },
                    child: const Text(
                      'Search for Device',
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
