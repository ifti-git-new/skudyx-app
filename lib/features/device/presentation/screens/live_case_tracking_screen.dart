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

  final _refreshController = RefreshController();

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
      s.clearRemotelyClosedStatus();
      _safePop(remote);
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    try {
      final session = context.read<DeviceSessionController>();

      if (session.caseId != null && session.tracking) {
        await session.realtime.watchCase(session.caseId!);
        await session.audioRealtime.watchCase(session.caseId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Refreshed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Refresh failed: $e')));
      }
    } finally {
      _refreshController.refreshCompleted();
    }
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
    _refreshController.dispose();
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
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          displacement: 40,
          child: CustomScrollView(
            controller: _refreshController.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🏷️ Header
                        const Text(
                          'Internal Testing (Dev/QA Only)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 📊 Case Info Card
                        Container(
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
                            'Updates: ok ${session.successUpdates} / fail ${session.failedUpdates}\n'
                            'Media active: ${session.audioActive}\n'
                            'WebSocket streaming: ${session.isWebSocketStreaming}\n'
                            'Media error: ${session.lastAudioError ?? '-'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🎙️ WebSocket Audio Status Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: session.isWebSocketStreaming
                                ? Colors.green.withOpacity(0.08)
                                : Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: session.isWebSocketStreaming
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    session.isWebSocketStreaming
                                        ? Icons.mic
                                        : Icons.mic_off,
                                    color: session.isWebSocketStreaming
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '🎙️ WebSocket Audio Streaming',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: session.isWebSocketStreaming
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Status: ${session.isWebSocketStreaming ? "✅ Streaming" : "⏸️ Not Active"}\n'
                                'Case ID: ${session.streamingCaseId ?? "-"}\n'
                                'Connection: ${session.isWebSocketStreaming ? "Connected" : "Disconnected"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // // 🔊 Active Listeners Card
                        // if (session.tracking && session.caseId != null)
                        //   Container(
                        //     padding: const EdgeInsets.all(12),
                        //     decoration: BoxDecoration(
                        //       color: Colors.green.withOpacity(0.08),
                        //       borderRadius: BorderRadius.circular(12),
                        //       border: Border.all(
                        //         color: Colors.green.withOpacity(0.3),
                        //       ),
                        //     ),
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         Row(
                        //           children: [
                        //             const Text(
                        //               '🔊 Active Listeners:',
                        //               style: TextStyle(
                        //                 fontWeight: FontWeight.bold,
                        //                 fontSize: 13,
                        //               ),
                        //             ),
                        //             const SizedBox(width: 8),
                        //             Container(
                        //               padding: const EdgeInsets.symmetric(
                        //                 horizontal: 8,
                        //                 vertical: 2,
                        //               ),
                        //               decoration: BoxDecoration(
                        //                 color: Colors.green,
                        //                 borderRadius: BorderRadius.circular(10),
                        //               ),
                        //               child: Text(
                        //                 '${session.webUserCount}',
                        //                 style: const TextStyle(
                        //                   color: Colors.white,
                        //                   fontSize: 11,
                        //                   fontWeight: FontWeight.bold,
                        //                 ),
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //         if (session.connectedWebUsers.isNotEmpty) ...[
                        //           const SizedBox(height: 6),
                        //           Text(
                        //             session.connectedWebUsers
                        //                 .map(
                        //                   (id) =>
                        //                       '• ${id.substring(0, id.length > 12 ? 12 : id.length)}...',
                        //                 )
                        //                 .join('\n'),
                        //             style: const TextStyle(
                        //               fontSize: 11,
                        //               color: Colors.grey,
                        //               fontFamily: 'monospace',
                        //             ),
                        //           ),
                        //         ] else if (session.audioActive) ...[
                        //           const SizedBox(height: 6),
                        //           const Text(
                        //             '⏳ Waiting for listeners...',
                        //             style: TextStyle(
                        //               fontSize: 11,
                        //               color: Colors.grey,
                        //               fontStyle: FontStyle.italic,
                        //             ),
                        //           ),
                        //         ],
                        //       ],
                        //     ),
                        //   ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Status Buttons
                        if (!session.tracking || session.caseId == null)
                          const Center(
                            child: Text(
                              'No active case running.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          )
                        else ...[
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
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
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
                                      : const Text('Resolved'),
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
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
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
                                      : const Text('Unresolved'),
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
                                      final note = await _askNote(
                                        context,
                                        'False',
                                      );
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
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
                                  : const Text('False'),
                            ),
                          ),
                        ],
                      ],
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
}

class RefreshController {
  final ScrollController scrollController = ScrollController();
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  void startRefresh() {
    _isRefreshing = true;
  }

  void refreshCompleted() {
    _isRefreshing = false;
  }

  void dispose() {
    scrollController.dispose();
  }
}
