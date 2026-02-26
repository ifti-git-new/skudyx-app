import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CaseDetailsScreen extends StatelessWidget {
  final String caseId;

  const CaseDetailsScreen({super.key, required this.caseId});

  static const _bg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // Bottom button like design
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 50,
            width: double.infinity,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download Case File (TODO)')),
                );
              },
              child: const Text(
                'Download Case File',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
          child: Column(
            children: [
              // Back chip + title
              Row(
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
                            'Case Details',
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

              const SizedBox(height: 14),

              // Top info card
              _Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Case ID:', caseId.isEmpty ? '#C1234567' : caseId),
                      const SizedBox(height: 10),
                      _kv('Agent ID:', '#A1234567'),
                      const SizedBox(height: 10),
                      _kv('Agent Name:', 'Jams Anderson'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Timeline card
              _Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    children: const [
                      _TimelineRow(
                        title: 'Case Created',
                        time: 'Sunday, Feb 02, 2026 12:00 PM',
                        isLast: false,
                      ),
                      _TimelineRow(
                        title: 'In Progress',
                        time: 'Sunday, Feb 02, 2026 12:00 PM',
                        isLast: false,
                      ),
                      _TimelineRow(
                        title: 'Resolved',
                        time: 'Sunday, Feb 02, 2026 12:00 PM',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Map card
              _Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "User’s Movement",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Placeholder map (replace with google_maps_flutter later)
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFE5E7EB),
                          image: const DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(
                              'https://staticmap.openstreetmap.de/staticmap.php?center=23.7806,90.4070&zoom=12&size=600x300&markers=23.7806,90.4070,lightblue1',
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: _line,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Audio card
              _Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // waveform placeholder
                      Expanded(
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            '||||||||||||||||||||||||||||||||||||',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Recording',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _line,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Text(
          k,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String time;
  final bool isLast;

  const _TimelineRow({
    required this.title,
    required this.time,
    required this.isLast,
  });

  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _line, width: 2),
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Positioned(
                    top: 22,
                    left: 12,
                    bottom: 0,
                    child: Container(width: 2, color: _line),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
