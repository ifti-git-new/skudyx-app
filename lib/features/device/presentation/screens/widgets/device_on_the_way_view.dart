import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/theme/app_colors.dart';

class DeviceOnTheWayView extends StatelessWidget {
  const DeviceOnTheWayView({super.key});

  static const _titleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                "Your device is on the way.\nWe’ll notify you when it\narrives.",
                textAlign: TextAlign.center,
                style: _titleStyle,
              ),
              const SizedBox(height: 26),

              const _TimelineItem(
                done: true,
                isLast: false,
                title: 'Order Placed',
                subtitle: 'Tuesday, Jan 27, 2026 12:34 PM',
              ),
              const SizedBox(height: 14),
              const _TimelineItem(
                done: true,
                isLast: false,
                title: 'Order Confirm',
                subtitle: 'Tuesday, Jan 27, 2026 12:34 PM',
              ),
              const SizedBox(height: 14),
              const _TimelineItem(
                done: false,
                isLast: true,
                title: 'Shipped',
                subtitle: 'Pending...',
              ),

              const Spacer(),

              // TEMP BUTTON
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
                  onPressed: () async {
                    // ✅ mark device arrived so /device no longer shows OnTheWay after restart
                    await context.read<AppStatusController>().setDeviceArrived(
                      true,
                    );

                    // go to Device Arrived screen (bluetooth connect screen)
                    if (context.mounted) context.push(AppRoutes.deviceArrived);
                  },
                  child: const Text(
                    'Shipped',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final bool done;
  final bool isLast;
  final String title;
  final String subtitle;

  const _TimelineItem({
    required this.done,
    required this.isLast,
    required this.title,
    required this.subtitle,
  });

  static const _borderColor = Color(0xFF38BDF8);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 20,
            top: 44,
            bottom: -14,
            child: Container(width: 2, color: _borderColor),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _borderColor : Colors.transparent,
                  border: Border.all(color: _borderColor, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
