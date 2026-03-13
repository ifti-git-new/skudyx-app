import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/core/storage/app_prefs.dart';
import 'package:skudyx/features/emergency_contact/data/remote/emergency_contact_api.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactController extends ChangeNotifier {
  final AppPrefs prefs;
  final EmergencyContactApi api;

  EmergencyContactModel? contact;
  bool phoneVerified = false;
  bool emailVerified = false;

  bool isSaving = false;
  String? errorMessage;

  EmergencyContactController({required this.prefs, required this.api});

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

  /// Local-only save (prefs + state)
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

  /// Backend save + local save
  Future<bool> saveContactToBackend(EmergencyContactModel model) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final contactName = model.fullName.trim().replaceAll(RegExp(r'\s+'), ' ');

      await api.saveEmergencyContact(
        contactName: contactName,
        phone: model.phone.trim(),
        email: model.email.trim(),
        relation: model.relation.trim(),
        address: model.address.trim(),
      );

      await saveContact(model);

      isSaving = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (e.message ?? 'Failed to save emergency contact.');

      isSaving = false;
      errorMessage = msg;
      notifyListeners();
      return false;
    } catch (_) {
      isSaving = false;
      errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
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
