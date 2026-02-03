import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/app_prefs.dart';

class EmergencyHomeScreen extends StatelessWidget {
  const EmergencyHomeScreen({super.key});

  static const _navy = Color(0xFF081B4A);

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<AppPrefs>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 240,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // ✅ Emergency button pressed logic
                final target = prefs.ecAdded
                    ? AppRoutes.emergencyContact
                    : AppRoutes.emergencyContactEdit;

                context.push(target);
              },
              child: const Text(
                'Add Emergency Contact',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
