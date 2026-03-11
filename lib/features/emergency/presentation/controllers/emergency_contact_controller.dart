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

    // If contact was previously added but app restarted, restore the data
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

    // Save flag to persistent storage so the "Why" screen doesn't show again
    await prefs.setEcAdded(true);

    // Reset verification for the new contact info
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
