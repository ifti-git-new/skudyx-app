import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';

import '../../../../core/controllers/app_status_controller.dart';
import '../../../../core/navigation/app_routes.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  const DeliveryDetailsScreen({super.key});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  static const _navy = Color(0xFF081B4A);
  static const _subText = Color(0xFF6B7280);

  final _firstName = TextEditingController(text: 'Jerome');
  final _phone = TextEditingController(text: '+12 345 6789');
  final _addr1 = TextEditingController(
    text: '21 East Dhanmondi, Dhaka, Bangladesh',
  );
  final _addr2 = TextEditingController(
    text: '21 East Dhanmondi, Dhaka, Bangladesh',
  );
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController(text: '-');

  String _country = '-';

  @override
  void dispose() {
    _firstName.dispose();
    _phone.dispose();
    _addr1.dispose();
    _addr2.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: SizedBox(
            width: double.infinity,
            height: 50, // Increased height for better mobile tap target
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    50,
                  ), // More rounded as per modern UI
                ),
              ),
              onPressed: () async {
                await context.read<AppStatusController>().setHasDeliveryDetails(
                  true,
                );
                if (context.mounted) context.go(AppRoutes.device);
              },
              child: Text(
                'Confirm',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header: Close Button with "Cancel" text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Cancel',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where should we deliver your SkudyX Emergency Button?',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 32, // Large bold header matching the image
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We’ll deliver your device to this address.",
                      style: AppTextStyles.caption.copyWith(
                        color: _subText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _LabeledField(label: 'First Name', controller: _firstName),
                    const SizedBox(height: 16),

                    _LabeledField(
                      label: 'Phone Number',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    _LabeledField(label: 'Address Line 1', controller: _addr1),
                    const SizedBox(height: 16),

                    _LabeledField(label: 'Address Line 2', controller: _addr2),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'City',
                            controller: _city,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledField(
                            label: 'State/Province',
                            controller: _state,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'ZIP/Postal Code',
                            controller: _zip,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CountryDropdown(
                            label: 'Country',
                            value: _country,
                            onTap: () async {
                              final selected =
                                  await showModalBottomSheet<String>(
                                    context: context,
                                    builder: (_) =>
                                        _CountrySheet(current: _country),
                                  );
                              if (selected != null) {
                                setState(() => _country = selected);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  static const _border = Color(0xFFE5E7EB);
  static const _fill =
      Colors.white; // Changed to white for cleaner look matching image
  static const _label = Color(0xFF6B7280);

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _label,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _fill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF081B4A),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  static const _border = Color(0xFFE5E7EB);
  static const _label = Color(0xFF6B7280);

  final String label;
  final String value;
  final VoidCallback onTap;

  const _CountryDropdown({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _label,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountrySheet extends StatelessWidget {
  final String current;
  const _CountrySheet({required this.current});

  @override
  Widget build(BuildContext context) {
    const items = [
      '-',
      'Bangladesh',
      'United States',
      'United Kingdom',
      'Canada',
      'India',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final v = items[i];
            return ListTile(
              title: Text(v),
              trailing: v == current
                  ? const Icon(Icons.check, color: Color(0xFF081B4A))
                  : null,
              onTap: () => Navigator.pop(context, v),
            );
          },
        ),
      ),
    );
  }
}
