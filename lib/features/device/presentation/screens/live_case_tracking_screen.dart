import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/features/device/presentation/controllers/device_session_controller.dart';

class LiveCaseTrackingScreen extends StatefulWidget {
  const LiveCaseTrackingScreen({super.key});

  @override
  State<LiveCaseTrackingScreen> createState() => _LiveCaseTrackingScreenState();
}

class _LiveCaseTrackingScreenState extends State<LiveCaseTrackingScreen> {
  bool _exiting = false;
  DeviceSessionController? _session;

  void _safePop([String? result]) {
    if (_exiting) return;
    _exiting = true;

    Future.microtask(() {
      if (!mounted) return;
      context.pop(result);
    });
  }

  void _onSessionChanged() {
    final s = _session;
    if (s == null) return;

    final remote = s.remotelyClosedStatus;
    if (remote != null && !_exiting) {
      // consume it so it doesn't trigger again
      s.clearRemotelyClosedStatus();
      _safePop(remote);
    }
  }

  Future<String?> _askNote(BuildContext context, String status) async {
    final ctrl = TextEditingController(
      text: 'Do you want to mark $status from app test button?',
    );

    final note = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Update Status: $status'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    ctrl.dispose();
    return note;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSession = context.read<DeviceSessionController>();

    if (_session != newSession) {
      _session?.removeListener(_onSessionChanged);
      _session = newSession;
      _session?.addListener(_onSessionChanged);
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();

    final statusText = session.starting
        ? 'Starting...'
        : session.tracking
        ? 'Tracking ON'
        : 'Tracking OFF';

    final bool enableStatusButtons =
        session.tracking && session.caseId != null && !session.statusUpdating;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Internal Testing (Dev/QA Only)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$statusText\n'
                    'Case: ${session.caseName ?? '-'}\n'
                    'case_id: ${session.caseId ?? (session.starting ? '(creating...)' : '-')}\n'
                    'Points: ${session.coordinates.length}\n'
                    'Updates: ok ${session.successUpdates} / fail ${session.failedUpdates}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                if (!session.tracking || session.caseId == null) ...[
                  const Text(
                    'No active case running.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.lastError ?? '',
                    style: const TextStyle(color: Colors.red),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: enableStatusButtons
                              ? () async {
                                  final note = await _askNote(
                                    context,
                                    'Resolved',
                                  );
                                  if (!mounted || note == null) return;

                                  final ok = await context
                                      .read<DeviceSessionController>()
                                      .updateFinalStatus(
                                        status: 'Resolved',
                                        note: note,
                                      );

                                  if (!mounted) return;

                                  if (ok) {
                                    _safePop('Resolved');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          session.lastError ?? 'Failed',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: session.statusUpdating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Resolved',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: enableStatusButtons
                              ? () async {
                                  final note = await _askNote(
                                    context,
                                    'Unresolved',
                                  );
                                  if (!mounted || note == null) return;

                                  final ok = await context
                                      .read<DeviceSessionController>()
                                      .updateFinalStatus(
                                        status: 'Unresolved',
                                        note: note,
                                      );

                                  if (!mounted) return;

                                  if (ok) {
                                    _safePop('Unresolved');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          session.lastError ?? 'Failed',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              179,
                              32,
                              32,
                            ),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: session.statusUpdating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Unresolved',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: enableStatusButtons
                          ? () async {
                              final note = await _askNote(context, 'False');
                              if (!mounted || note == null) return;

                              final ok = await context
                                  .read<DeviceSessionController>()
                                  .updateFinalStatus(
                                    status: 'False',
                                    note: note,
                                  );

                              if (!mounted) return;

                              if (ok) {
                                _safePop('False');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      session.lastError ?? 'Failed',
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7280),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: session.statusUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'False',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
