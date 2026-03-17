import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/features/profile/controllers/profile_controller.dart';
import 'package:skudyx/features/profile/data/remote/profile_update_api.dart';

class EditProfileController extends ChangeNotifier {
  final ProfileUpdateApi updateApi;
  final ProfileController profile; // we will refresh this after update

  EditProfileController({required this.updateApi, required this.profile});

  bool isUpdating = false;
  String? errorMessage;

  Future<bool> submit({
    required String firstName,
    required String lastName,
    required String phone,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String zip,
    required String country,
  }) async {
    if (isUpdating) return false;

    isUpdating = true;
    errorMessage = null;
    notifyListeners();

    try {
      await updateApi.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        zipPostalCode: zip,
        country: country,
      );

      // ✅ Refresh the main ProfileController so ProfileScreen updates immediately
      await profile.loadProfile(force: true);

      isUpdating = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (e.message ?? 'Failed to update profile.');
      isUpdating = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      isUpdating = false;
      notifyListeners();
      return false;
    }
  }
}
