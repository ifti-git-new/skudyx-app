import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/features/cases/presentation/controllers/live_case_call_controller.dart';
import 'package:skudyx/features/device/presentation/controllers/device_session_controller.dart';
import 'package:skudyx/features/device/presentation/screens/live_case_tracking_screen.dart';

Future<void> startLiveCaseFlow({
  required BuildContext context,
  required String socketBaseUrl,
  required String uploadBaseUrl,
  required String uploadEndpoint,
  required Future<bool> Function(DeviceSessionController session)
  startCaseAction,
}) async {
  final session = context.read<DeviceSessionController>();

  final created = await startCaseAction(session);
  if (!context.mounted) return;

  if (!created || session.caseId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(session.lastError ?? 'Failed to start live case')),
    );
    return;
  }

  final callController = LiveCaseCallController(
    socketBaseUrl: socketBaseUrl,
    uploadBaseUrl: uploadBaseUrl,
    uploadEndpoint: uploadEndpoint,
    caseId: session.caseId.toString(),
    isCaller: true,
  );

  await callController.start();

  if (!context.mounted) return;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider<LiveCaseCallController>.value(
            value: callController,
          ),
        ],
        child: const LiveCaseTrackingScreen(),
      ),
    ),
  );
}
