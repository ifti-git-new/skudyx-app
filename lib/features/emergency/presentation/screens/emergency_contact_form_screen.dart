import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/core/theme/app_text_styles.dart';
import 'package:skudyx/features/emergency/presentation/controllers/emergency_contact_controller.dart';
import 'package:skudyx/features/emergency/data/models/emergency_contact_model.dart';

class EmergencyContactFormScreen extends StatefulWidget {
  const EmergencyContactFormScreen({super.key});

  @override
  State<EmergencyContactFormScreen> createState() =>
      _EmergencyContactFormScreenState();
}

class _EmergencyContactFormScreenState
    extends State<EmergencyContactFormScreen> {
  static const _navy = Color(0xFF081B4A);
  static const _sub = Color(0xFF6B7280);

 final first = TextEditingController();
final last = TextEditingController();
final phone = TextEditingController();
final email = TextEditingController();
final relation = TextEditingController();
final address = TextEditingController();
bool _isInitialized = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();

  final contact = context.read<EmergencyContactController>().contact;

  if (!_isInitialized && contact != null) {
    first.text = contact.firstName;
    last.text = contact.lastName;
    phone.text = contact.phone;
    email.text = contact.email;
    relation.text = contact.relation;
    address.text = contact.address;

    _isInitialized = true;
  }
}

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    phone.dispose();
    email.dispose();
    relation.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyContactController>();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: controller.isSaving
                  ? null
                  : () async {
                      final model = EmergencyContactModel(
                        firstName: first.text.trim(),
                        lastName: last.text.trim(),
                        phone: phone.text.trim(),
                        email: email.text.trim(),
                        relation: relation.text.trim(),
                        address: address.text.trim(),
                      );

                      final ok = await context
                          .read<EmergencyContactController>()
                          .saveContactToBackend(model);

                      if (!context.mounted) return;

                      if (ok) {
                        context.go(AppRoutes.emergencyContact);
                      } else {
                        final msg =
                            context
                                .read<EmergencyContactController>()
                                .errorMessage ??
                            'Failed to save emergency contact.';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
              child: controller.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Contact',
                style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Lorem ipsum dolor sit amet adipiscing elit.',
                style: AppTextStyles.body.copyWith(color: _sub),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact Details',
                style: AppTextStyles.textfont16.copyWith(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LabelField(label: 'First Name', controller: first),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabelField(label: 'Last Name', controller: last),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LabelField(label: 'Phone Number', controller: phone),
              const SizedBox(height: 12),
              _LabelField(label: 'Email', controller: email),
              const SizedBox(height: 12),
              _LabelField(label: 'Relation', controller: relation),
              const SizedBox(height: 12),
              _LabelField(label: 'Address', controller: address),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _LabelField({required this.label, required this.controller});

  static const _border = Color(0xFFE5E7EB);
  static const _fill = Color(0xFFF6F7F9);
  static const _sub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textfont.copyWith(
            color: _sub,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
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
