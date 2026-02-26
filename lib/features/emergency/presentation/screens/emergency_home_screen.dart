import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/storage/app_prefs.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

class EmergencyHomeScreen extends StatelessWidget {
  const EmergencyHomeScreen({super.key});

  // Colors based on the provided UI design
  static const _navy = Color(0xFF081B4A);
  static const _lightGrey = Color(0xFFE9EBEF);
  static const _textGrey = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/add_emergency_contact.png'),
              const SizedBox(height: 32),
              Text(
                'Why we need this',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Description
              Text(
                'Your emergency contact is the first person we notify when you press the SkudyX button. Adding this now helps us reach someone you trust as quickly as possible during an emergency.',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2light.copyWith(
                  fontSize: 16,
                  height: 1.5,
                  color: _textGrey,
                ),
              ),
              const SizedBox(height: 40),

              // 4. "Add Emergency Contact" Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: _lightGrey,
                    shape: const StadiumBorder(), // Makes it a pill shape
                  ),
                  onPressed: () {
                    final prefs = context.read<AppPrefs>();

                    // Keep your required navigation logic
                    final target = prefs.ecAdded
                        ? AppRoutes.emergencyContact
                        : AppRoutes.emergencyContactEdit;

                    context.push(target);
                  },
                  child: const Text(
                    'Add Emergency Contact',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
