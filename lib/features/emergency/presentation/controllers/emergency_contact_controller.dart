import 'package:flutter/foundation.dart';
import 'package:skudyx/core/storage/app_prefs.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactController extends ChangeNotifier {
  final AppPrefs prefs;

  EmergencyContactModel? contact;

  bool phoneVerified = false;
  bool emailVerified = false;

  EmergencyContactController({required this.prefs});

  Future<void> init() async {
    // UI-only: We only persist flags for now.
    phoneVerified = prefs.ecPhoneVerified;
    emailVerified = prefs.ecEmailVerified;

    // If contact added flag false, keep contact null
    if (!prefs.ecAdded) {
      contact = null;
    } else {
      // Optional: you can later persist actual contact data
      // For now we keep a demo contact so overview shows values.
      contact ??= const EmergencyContactModel(
        firstName: 'Jerome',
        lastName: 'Bell',
        phone: '+12 345 6789',
        email: 'jerome.bell@yourmail.com',
        relation: '-',
        address: '21 East  Dhanmondi, Dhaka, Bangladesh',
      );
    }

    notifyListeners();
  }

  Future<void> saveContact(EmergencyContactModel model) async {
    contact = model;

    // after save -> mark added, but verification resets
    await prefs.setEcAdded(true);

    phoneVerified = false;
    emailVerified = false;
    await prefs.setEcPhoneVerified(false);
    await prefs.setEcEmailVerified(false);

    notifyListeners();
  }

  Future<void> setPhoneVerified(bool v) async {
    phoneVerified = v;
    await prefs.setEcPhoneVerified(v);
    notifyListeners();
  }

  Future<void> setEmailVerified(bool v) async {
    emailVerified = v;
    await prefs.setEcEmailVerified(v);
    notifyListeners();
  }

  bool get isAdded => contact != null;
}
