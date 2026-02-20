import 'package:flutter/foundation.dart';

class ProfileController extends ChangeNotifier {
  String firstName = 'Theresa';
  String lastName = 'Webb';

  int profilePercent = 75;

  String phone = '+12 345 6789';
  bool phoneVerified = true;

  String email = 'jerome.bell@yourmail.com';
  bool emailVerified = true;

  String addressLine1 = '';
  String addressLine2 = '';
  String city = '';
  String state = '';
  String zip = '';
  String country = '';

  bool identityVerified = false;

  String get fullName => '$firstName $lastName';

  String get addressDisplay {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      state,
      zip,
      country,
    ].where((e) => e.trim().isNotEmpty).toList();

    if (parts.isEmpty) return '21 East  Dhanmondi, Dhaka, Bangladesh';
    return parts.join(', ');
  }

  void updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String zip,
    required String country,
  }) {
    if (this.phone.trim() != phone.trim()) {
      phoneVerified = false;
    }

    this.firstName = firstName.trim();
    this.lastName = lastName.trim();
    this.phone = phone.trim();

    this.addressLine1 = addressLine1.trim();
    this.addressLine2 = addressLine2.trim();
    this.city = city.trim();
    this.state = state.trim();
    this.zip = zip.trim();
    this.country = country.trim();

    notifyListeners();
  }

  void setIdentityVerified(bool v) {
    identityVerified = v;
    notifyListeners();
  }
}
