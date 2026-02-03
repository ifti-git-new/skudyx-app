import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  static const _border = Color(0xFFE5E7EB);
  static const _fill = Color(0xFFF6F7F9);

  final _firstName = TextEditingController(text: 'Jerome');
  final _phone = TextEditingController(text: '+12 345 6789');
  final _addr1 = TextEditingController(
    text: '21 East  Dhanmondi, Dhaka, Bangladesh',
  );
  final _addr2 = TextEditingController(
    text: '21 East  Dhanmondi, Dhaka, Bangladesh',
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // UI-only: mark delivery details completed
                await context.read<AppStatusController>().setHasDeliveryDetails(
                  true,
                );

                // go back to Device tab; it will show "Device is on the way"
                if (context.mounted) context.go(AppRoutes.device);
              },
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Back chip row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
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
                      child: Row(
                        children: const [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Where should we deliver your SkudyX\nEmergency Button?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "We’ll deliver your device to this address.",
                      style: TextStyle(fontSize: 14, color: _subText),
                    ),
                    const SizedBox(height: 18),

                    _LabeledField(label: 'First Name', controller: _firstName),
                    const SizedBox(height: 12),

                    _LabeledField(
                      label: 'Phone Number',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    _LabeledField(label: 'Address Line 1', controller: _addr1),
                    const SizedBox(height: 12),

                    _LabeledField(label: 'Address Line 2', controller: _addr2),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'City',
                            controller: _city,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'State/Province',
                            controller: _state,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'ZIP/Postal Code',
                            controller: _zip,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              if (selected != null)
                                setState(() => _country = selected);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 90),
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
  static const _fill = Color(0xFFF6F7F9);
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
            fontSize: 13,
            color: _label,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: _fill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF081B4A),
                width: 1.4,
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
  static const _fill = Color(0xFFF6F7F9);
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
            fontSize: 13,
            color: _label,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 14)),
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

    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final v = items[i];
          return ListTile(
            title: Text(v),
            trailing: v == current ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, v),
          );
        },
      ),
    );
  }
}
