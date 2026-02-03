import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/emergency_contact_controller.dart';
import '../models/emergency_contact_model.dart';

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
  static const _border = Color(0xFFE5E7EB);
  static const _fill = Color(0xFFF6F7F9);

  final first = TextEditingController(text: 'Jerome');
  final last = TextEditingController(text: 'Bell');
  final phone = TextEditingController(text: '+12 345 6789');
  final email = TextEditingController(text: 'jerome.bell@yourmail.com');
  final relation = TextEditingController(text: '-');
  final address = TextEditingController(
    text: '21 East  Dhanmondi, Dhaka, Bangladesh',
  );

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
    final controller = context.read<EmergencyContactController>();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: SizedBox(
            height: 54,
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
              onPressed: () async {
                await controller.saveContact(
                  EmergencyContactModel(
                    firstName: first.text.trim(),
                    lastName: last.text.trim(),
                    phone: phone.text.trim(),
                    email: email.text.trim(),
                    relation: relation.text.trim(),
                    address: address.text.trim(),
                  ),
                );
                if (context.mounted) context.pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
              const Text(
                'Emergency Contact',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lorem ipsum dolor sit amet adipiscing elit.',
                style: TextStyle(fontSize: 16, color: _sub),
              ),
              const SizedBox(height: 20),

              const Text(
                'Contact Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
          style: const TextStyle(
            fontSize: 13,
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
