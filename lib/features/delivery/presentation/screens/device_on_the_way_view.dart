import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/controllers/app_status_controller.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/theme/app_colors.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/delivery/presentation/controller/delivery_details_controller.dart';

class DeviceOnTheWayView extends StatefulWidget {
  const DeviceOnTheWayView({super.key});

  // static final _dateFormat = DateFormat("EEEE, MMM d, yyyy h:mm a");

  // Define the static steps (title ↔ API status value)
  static const _steps = [
    _StepInfo(title: 'Order Placed', statusKey: 'Placed'),
    _StepInfo(title: 'Order Confirm', statusKey: 'confirmed'),
    _StepInfo(title: 'Shipped', statusKey: 'Shipped'),
  ];

  @override
  State<DeviceOnTheWayView> createState() => _DeviceOnTheWayViewState();
}

class _DeviceOnTheWayViewState extends State<DeviceOnTheWayView> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeviceDeliveryController>(); // adjust to your actual controller
    final order = controller.orderDetailsModel;

    // Show loading spinner if order is still being fetched
    if (controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('No order information available')),
      );
    }

    // Determine current step index based on global status.
    // If the status is unknown, assume 0.
    final currentIdx = DeviceOnTheWayView._steps.indexWhere((s) => s.statusKey == order.data?.status);
    final effectiveIdx = currentIdx >= 0 ? currentIdx : -1; // -1 means no step done

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Text(
                "Your device is on the way.\nWe’ll notify you when it\narrives.",
                textAlign: TextAlign.center,
                style: AppTextStyles.h2light.copyWith(height: 1.25),
              ),
              const SizedBox(height: 26),

              // Build dynamic timeline
              ...List.generate(DeviceOnTheWayView._steps.length, (i) {
                final step = DeviceOnTheWayView._steps[i];
                final done = i <= effectiveIdx;
                // final timelineEntry = order.data?.timeline?.firstWhere(
                //   (t) => t.status == step.statusKey,
                //   orElse: () => null,
                //);
                // final subtitle = timelineEntry != null
                //     ? _formatTimestamp(timelineEntry.timestamp)
                //     : done
                //         ? _formatTimestamp(order.createdAt) // fallback: order creation date
                //         : 'Pending...';

                return Padding(
                  padding: EdgeInsets.only(bottom: i == DeviceOnTheWayView._steps.length - 1 ? 0 : 14),
                  child: _TimelineItem(
                    done: done,
                    isLast: i == DeviceOnTheWayView._steps.length - 1,
                    title: step.title,
                    subtitle: '',
                  ),
                );
              }),

              const Spacer(),
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
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: _muted,
                      ),
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

class _StepInfo {
  final String title;
  final String statusKey;
  const _StepInfo({required this.title, required this.statusKey});
}