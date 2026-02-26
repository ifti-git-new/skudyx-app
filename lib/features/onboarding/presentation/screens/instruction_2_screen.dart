import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../core/widgets/sk_primary_button.dart';

class Instruction2Screen extends StatelessWidget {
  const Instruction2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [SquareBackButton(onTap: () => context.pop())],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Features',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Feature 1: Alert Emergency
                      const _Feature(
                        bg: Color(0xFFFFE5E5),
                        imagePath:
                            'assets/images/warning_icon.png', // Update to your specific red icon PNG
                        title: 'Alert Emergency Contact',
                        desc: 'Notifies your trusted contact instantly.',
                      ),
                      const SizedBox(height: 40),
                      // Feature 2: Live Location
                      const _Feature(
                        bg: Color(0xFFE6F0FF),
                        imagePath:
                            'assets/images/live_location_icon.png', // Update to your specific blue icon PNG
                        title: 'Share Your Live Location',
                        desc:
                            'Sends your real-time location to help find you quickly.',
                      ),
                      const SizedBox(height: 40),
                      // Feature 3: Live Audio
                      const _Feature(
                        bg: Color(0xFFE7F9EE),
                        imagePath:
                            'assets/images/stream_icon.png', // Update to your specific green icon PNG
                        title: 'Stream Live Audio',
                        desc:
                            'Streams audio from your phone to the support team for real-time assistance.',
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: SkPrimaryButton(
                text: 'Next',
                onPressed: () => context.push(AppRoutes.instruction3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final Color bg;
  final String imagePath;
  final String title;
  final String desc;

  const _Feature({
    required this.bg,
    required this.imagePath,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Responsive Circle with PNG Image
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          alignment: Alignment.center,
          child: Image.asset(
            imagePath,
            width: 32, // Adjust size to fit nicely in the circle
            height: 32,
            fit: BoxFit.contain,
            // If your PNGs are monochrome and you need to color them:
            // color: someColor,
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.h2.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // Description
        Text(
          desc,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            fontSize: 15,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
