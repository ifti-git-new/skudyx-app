import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CaseDetailsScreen extends StatelessWidget {
  final String caseId;

  const CaseDetailsScreen({super.key, required this.caseId});

  static const _bg = Color(0xFFF7F8FA);
  static const _navy = Color(0xFF081B4A);
  static const _muted = Color(0xFF6B7280);
  static const _accentBlue = Color(0xFF38BDF8);
  static const _cardBorder = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bg, // Match your screen background color
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents color change on scroll
        automaticallyImplyLeading:
            false, // We are providing our own leading widget
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Case Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: _bg,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download Case File (TODO)')),
                );
              },
              child: const Text(
                'Download Case File',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row(
              //   children: [
              //     InkWell(
              //       onTap: () => context.pop(),
              //       borderRadius: BorderRadius.circular(12),
              //       child: Container(
              //         height: 44,
              //         width: 44,
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           borderRadius: BorderRadius.circular(12),
              //           border: Border.all(color: _cardBorder),
              //         ),
              //         child: const Icon(Icons.arrow_back, size: 20),
              //       ),
              //     ),
              //     const SizedBox(width: 16),
              //     const Text(
              //       'Case Details',
              //       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 20),

              // Agent Info Card
              _Card(
                child: Column(
                  children: [
                    _kv(
                      'Case ID:',
                      caseId.isEmpty ? '#CL-2601-234214' : caseId,
                    ),
                    const SizedBox(height: 12),
                    _kv('Agent ID:', '#SA-2601-123457'),
                    const SizedBox(height: 12),
                    _kv('Agent Name:', 'Jams Anderson'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Status History Card (Text Style)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _StatusItem(
                      label: 'Created',
                      time: 'Sunday, Feb 02, 2026 12:00 PM',
                    ),
                    _StatusItem(
                      label: 'In Progress',
                      time: 'Sunday, Feb 02, 2026 12:00 PM',
                    ),
                    _StatusItem(
                      label: 'Escalated',
                      time: 'Sunday, Feb 02, 2026 12:00 PM',
                    ),
                    _StatusItem(
                      label: 'Resolved',
                      time: 'Sunday, Feb 02, 2026 12:00 PM',
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Map Card
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "User’s Movement",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.network(
                            'https://staticmap.openstreetmap.de/staticmap.php?center=23.7806,90.4070&zoom=14&size=600x300',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.map_outlined,
                                      color: _muted,
                                    ),
                                  ),
                                ),
                          ),
                          const Positioned(
                            right: 12,
                            bottom: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 20,
                              child: Icon(
                                Icons.navigation,
                                color: _accentBlue,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Audio Card
              _Card(
                child: Row(
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: 0.2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            28,
                            (i) => Container(
                              width: 2,
                              height: (i % 5 == 0)
                                  ? 24
                                  : (i % 3 == 0)
                                  ? 16
                                  : 10,
                              color: _navy,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recording',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    const CircleAvatar(
                      backgroundColor: _accentBlue,
                      radius: 18,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
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
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w400),
        ),
        const SizedBox(width: 8),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String time;
  final bool isLast;

  const _StatusItem({
    required this.label,
    required this.time,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
