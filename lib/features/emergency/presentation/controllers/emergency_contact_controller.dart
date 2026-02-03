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
    phoneVerified = prefs.ecPhoneVerified;
    emailVerified = prefs.ecEmailVerified;

    // If contact added but app restarted, we still show a demo contact (UI-only)
    if (prefs.ecAdded && contact == null) {
      contact = const EmergencyContactModel(
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

    // ✅ IMPORTANT: This is what your emergency routing checks
    await prefs.setEcAdded(true);

    // reset verification
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
}
