import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

class DeviceConnectedScreen extends StatelessWidget {
  const DeviceConnectedScreen({super.key});

  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE5E7EB);

  static const Color _green = Color(0xFF22C55E);
  static const Color _greenSoft = Color(0xFFDFF7DF);

  static const Color _red = Color(0xFFE11D48);
  static const Color _redSoft = Color(0xFFFFE4E6);

  static const Color _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: back + Disconnect label
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Disconnect',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Device circle + tick badge
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green, width: 3),
                        color: Colors.white,
                      ),
                      child: Center(child: _DeviceButtonMock()),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _green,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // BLE info card
              _CardShell(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          Text(
                            'BLE Device',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),

                          // ✅ Animated press (scale + ripple) + onTap disconnect
                          _TapScale(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.go(AppRoutes.deviceList);
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: const _Pill(
                              text: 'Connected',
                              bg: _greenSoft,
                              fg: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _border),
                    const _KeyValueRow(left: 'Battery', right: '50%'),
                    const Divider(height: 1, color: _border),
                    const _KeyValueRow(
                      left: 'Subscription Plan',
                      right: 'Basic',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Shared Information:',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              const _FeatureRow(
                title: 'Current Location',
                pill: _Pill(
                  text: 'Active',
                  bg: _greenSoft,
                  fg: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 12),
              const _FeatureRow(
                title: 'Track Movement',
                pill: _Pill(text: 'Inactive', bg: _redSoft, fg: _red),
              ),
              const SizedBox(height: 12),
              const _FeatureRow(
                title: 'Record Audio',
                pill: _Pill(text: 'Inactive', bg: _redSoft, fg: _red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Press animation wrapper: scales down on tap-down + ripple.
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _TapScale({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Mock of the black SkudyX emergency button (until you add real image asset).
class _DeviceButtonMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 10),
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DeviceConnectedScreen._border),
        borderRadius: BorderRadius.circular(16),
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

class _KeyValueRow extends StatelessWidget {
  final String left;
  final String right;

  const _KeyValueRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Text(
            left,
            style: AppTextStyles.caption.copyWith(
              color: DeviceConnectedScreen._textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            right,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;
  final Widget pill;

  const _FeatureRow({required this.title, required this.pill});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeviceConnectedScreen._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          pill,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
