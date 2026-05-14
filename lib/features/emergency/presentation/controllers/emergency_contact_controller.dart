import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/core/storage/app_prefs.dart';
import 'package:skudyx/features/emergency/data/remote/emergency_contact_api.dart';
import '../../data/models/emergency_contact_model.dart';

class EmergencyContactController extends ChangeNotifier {
  final AppPrefs prefs;
  final EmergencyContactApi api;

  EmergencyContactModel? contact;
  bool phoneVerified = false;
  bool emailVerified = false;

  bool isSaving = false;
  bool isLoading = false;
  String? errorMessage;

  EmergencyContactController({required this.prefs, required this.api});

  Future<void> init() async {
    phoneVerified = prefs.ecPhoneVerified;
    emailVerified = prefs.ecEmailVerified;
    await getContactFromBackend();
    // Fetch live contact from backend if one was previously saved
    // if (prefs.ecAdded && contact == null) {
    //   await getContactFromBackend();
    //   // getContactFromBackend calls notifyListeners() internally, so we return
    //   // early to avoid a redundant extra notify below.
    //   return;
    // }

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

  /// Fetch emergency contact from backend and hydrate local state.
  /// Returns true on success, false on failure (check [errorMessage]).
 Future<bool> getContactFromBackend() async {
  if (isLoading) return false;

  isLoading = true;
  errorMessage = null;
  contact = null;           // reset to prevent stale data
  notifyListeners();

  try {
    final data = await api.getEmergencyContact();

    // ✅ No data means no contact (either 404 or empty response)
    if (data == null) {
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return false;
    }

    // Parse the contact
    final rawName = (data['contact_name'] as String? ?? '').trim();
    final spaceIndex = rawName.indexOf(' ');
    final firstName =
        spaceIndex != -1 ? rawName.substring(0, spaceIndex) : rawName;
    final lastName =
        spaceIndex != -1 ? rawName.substring(spaceIndex + 1) : '';

    contact = EmergencyContactModel(
      firstName: firstName,
      lastName: lastName,
      phone: (data['phone'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? '').trim(),
      relation: (data['relation'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
    );

    await prefs.setEcAdded(true);

    isLoading = false;
    errorMessage = null;
    notifyListeners();
    return true;
  } on DioException catch (e) {
    // ✅ 404 means no contact – not an error
    if (e.response?.statusCode == 404) {
      contact = null;
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return false;
    }

    // ❌ Real server / network error
    final body = e.response?.data;
    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : (e.message ?? 'Failed to fetch emergency contact.');

    isLoading = false;
    errorMessage = msg;
    notifyListeners();
    return false;
  } catch (_) {
    isLoading = false;
    errorMessage = 'Something went wrong. Please try again.';
    notifyListeners();
    return false;
  }
}

  Future<bool> verifyContact({
    required String type,
    required String otp,
  }) async {
    try {
      errorMessage = null;
      await api.verifyEmergencyContact(type: type, otp: otp);
      if (type == 'phone') {
        phoneVerified = true;
      } else {
        emailVerified = true;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
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
