import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skudyx/features/profile/controllers/edit_profile_controller.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';
import 'package:skudyx/features/profile/data/remote/profile_update_api.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _navy = Color(0xFF081B4A);
  static const _subText = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  late final EditProfileController edit;

  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController phone;

  late final TextEditingController address1;
  late final TextEditingController address2;

  late final TextEditingController city;
  late final TextEditingController state;
  late final TextEditingController zip;
  late final TextEditingController country;

  @override
  void initState() {
    super.initState();

    final profile = context.read<ProfileController>();

    // ✅ Create edit controller (separate from ProfileController)
    edit = EditProfileController(
      updateApi: context.read<ProfileUpdateApi>(),
      profile: profile,
    );

    firstName = TextEditingController(text: profile.firstName);
    lastName = TextEditingController(text: profile.lastName);
    phone = TextEditingController(text: profile.phone);

    address1 = TextEditingController(text: profile.addressLine1);
    address2 = TextEditingController(text: profile.addressLine2);

    city = TextEditingController(text: profile.city);
    state = TextEditingController(text: profile.state);
    zip = TextEditingController(text: profile.zip);
    country = TextEditingController(text: profile.country);
  }

  @override
  void dispose() {
    edit.dispose();
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    address1.dispose();
    address2.dispose();
    city.dispose();
    state.dispose();
    zip.dispose();
    country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ChangeNotifierProvider.value(
      value: edit,
      child: Consumer<EditProfileController>(
        builder: (context, edit, _) {
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: edit.isUpdating
                          ? null
                          : () async {
                              final ok = await edit.submit(
                                firstName: firstName.text,
                                lastName: lastName.text,
                                phone: phone.text,
                                addressLine1: address1.text,
                                addressLine2: address2.text,
                                city: city.text,
                                state: state.text,
                                zip: zip.text,
                                country: country.text,
                              );

                              if (!context.mounted) return;

                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                    ),
                                  ),
                                );
                                context.pop();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      edit.errorMessage ?? 'Update failed',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: edit.isUpdating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Updating...',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              body: SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 16),

                      if (edit.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withAlpha(60)),
                          ),
                          child: Text(
                            edit.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],

                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _LabelField(
                              label: 'First Name',
                              controller: firstName,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabelField(
                              label: 'Last Name',
                              controller: lastName,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _LabelField(
                        label: 'Phone Number (OTP verification required)',
                        controller: phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      _LabelField(
                        label: 'Address Line 1',
                        controller: address1,
                      ),
                      const SizedBox(height: 12),

                      _LabelField(
                        label: 'Address Line 2',
                        controller: address2,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _LabelField(label: 'City', controller: city),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabelField(
                              label: 'State/Province',
                              controller: state,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _LabelField(
                              label: 'ZIP/Postal Code',
                              controller: zip,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabelField(
                              label: 'Country',
                              controller: country,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Upload Profile Photo',
                        style: TextStyle(
                          fontSize: 13,
                          color: _subText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Upload Profile Photo (TODO)'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 82,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_rounded,
                                size: 26,
                                color: Colors.black,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LabelField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabelField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  static const _border = Color(0xFFE5E7EB);
  static const _fill = Color(0xFFF6F7F9);
  static const _subText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _subText,
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
