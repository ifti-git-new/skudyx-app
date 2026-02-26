import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/theme/app_colors.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

import 'package:skudyx/features/settings/presentation/controllers/notification_prefs_controller.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  static const _bg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificationPrefsController>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: c.permissionGranted
                  ? _ToggleList(c: c)
                  : _PermissionOffView(c: c),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionOffView extends StatelessWidget {
  final NotificationPrefsController c;
  const _PermissionOffView({required this.c});

  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications are\nturned off',
            style: AppTextStyles.h2light.copyWith(
              // fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enable notifications to receive emergency\nalerts and device updates.',
            style: AppTextStyles.subtitle.copyWith(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () async {
                final status = await c.requestPermission();

                if (status.isGranted) {
                  await c.refreshPermission();
                  return;
                }

                // Denied or permanently denied -> show bottom sheet with Open Settings
                if (context.mounted) {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    builder: (_) => const _EnableInSettingsSheet(),
                  );
                }
              },
              child: Text(
                'Enable Notifications',
                style: AppTextStyles.button.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnableInSettingsSheet extends StatelessWidget {
  const _EnableInSettingsSheet();

  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 10,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle + close
            Row(
              children: [
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enable notifications in settings',
                style: AppTextStyles.textfont16.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Open your phone settings, find SkudyX app,\nand allow notifications.',
                style: AppTextStyles.caption.copyWith(
                  color: _muted,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE5E7EB),
                        foregroundColor: _navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Maybe Later',
                        style: AppTextStyles.textfont.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await openAppSettings();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        'Open Settings',
                        style: AppTextStyles.textfont.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.bg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleList extends StatelessWidget {
  final NotificationPrefsController c;
  const _ToggleList({required this.c});

  static const _border = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
      children: [
        _ToggleCard(
          title: 'App Setup Reminders',
          subtitle: 'Reminders to complete required steps to activate\nSkudyX.',
          value: c.setupReminders,
          onChanged: c.setSetupReminders,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Delivery Updates',
          subtitle:
              'Notifications about your device shipping and delivery\nstatus.',
          value: c.deliveryUpdates,
          onChanged: c.setDeliveryUpdates,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Emergency Alerts',
          subtitle: 'Alerts related to active or recent emergency cases.',
          value: c.emergencyAlerts,
          onChanged: c.setEmergencyAlerts,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'System Announcements',
          subtitle: 'Important system updates and service information.',
          value: c.systemAnnouncements,
          onChanged: c.setSystemAnnouncements,
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  static const _border = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _muted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
