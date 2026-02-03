import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/storage/app_prefs.dart';

class EmergencyHomeScreen extends StatelessWidget {
  const EmergencyHomeScreen({super.key});

  static const _navy = Color(0xFF081B4A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 260,
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
                final prefs = context.read<AppPrefs>();

                // ✅ REQUIRED LOGIC
                final target = prefs.ecAdded
                    ? AppRoutes.emergencyContact
                    : AppRoutes.emergencyContactEdit;

                context.push(target);
              },
              child: const Text(
                'Press Emergency Button',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
