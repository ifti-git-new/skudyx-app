import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  static const _navy = Color(0xFF081B4A);

  // Change later to your real support email
  static const _supportEmail = 'support@skudyx.com';

  late final TextEditingController first;
  late final TextEditingController last;
  late final TextEditingController email;
  final message = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Prefill from ProfileController (fallback values if empty)
    // If ProfileController isn't in your providers, replace with hardcoded strings.
    // ignore: avoid_init_to_null
    ProfileController? p;
    try {
      p = context.read<ProfileController>();
    } catch (_) {
      p = null;
    }

    first = TextEditingController(text: p?.firstName ?? 'Jerome');
    last = TextEditingController(text: p?.lastName ?? 'Bell');
    email = TextEditingController(text: p?.email ?? 'jerome.bell@yourmail.com');
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    email.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body =
        """
First Name: ${first.text.trim()}
Last Name: ${last.text.trim()}
Email: ${email.text.trim()}

Message:
${message.text.trim()}

---
(App will attach User ID / Device info later)
""";

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'SkudyX Contact Support', 'body': body},
    );

    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open email app on this device.'),
        ),
      );
      return;
    }

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,

        bottomNavigationBar: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(22, 0, 22, 18 + bottomInset),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _submit,
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back chip
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 18),

                // First/Last row
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'First Name',
                        controller: first,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Last Name',
                        controller: last,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _LabeledField(
                  label: 'Email',
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 14),

                _LabeledMultiField(label: 'Message', controller: message),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

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

class _LabeledMultiField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _LabeledMultiField({required this.label, required this.controller});

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
          minLines: 5,
          maxLines: 6,
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
