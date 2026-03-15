import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/features/profile/data/remote/profile_api.dart';

class ProfileController extends ChangeNotifier {
  final ProfileApi api;

  ProfileController({required this.api});

  // UI state
  bool isLoading = false;
  String? errorMessage;
  bool _loadedOnce = false;

  // Existing fields
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

    if (parts.isEmpty) return '—';
    return parts.join(', ');
  }

  /// Call from ProfileScreen initState and RefreshIndicator.
  Future<void> loadProfile({bool force = false}) async {
    if (_loadedOnce && !force) return;
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final body = await api.getProfile();

      // completion_percentage
      profilePercent = (body['completion_percentage'] as num?)?.toInt() ?? 0;

      final data = body['data'];
      log('Profile data loaded: $data');
      if (data is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/v1/users/profile'),
          error: 'Invalid profile response: data is missing',
        );
      }

      // Map fields from response
      firstName = (data['first_name'] ?? firstName).toString();
      lastName = (data['last_name'] ?? lastName).toString();

      phone = (data['phone'] ?? phone).toString();
      email = (data['email'] ?? email).toString();

      phoneVerified = (data['phoneVerified'] as bool?) ?? phoneVerified;
      emailVerified = (data['emailVerified'] as bool?) ?? emailVerified;

      // address + parts
      addressLine1 = (data['address'] ?? '').toString();
      addressLine2 = (data['address_line_2'] ?? '').toString();
      city = (data['city'] ?? '').toString();
      state = (data['state'] ?? '').toString();
      zip = (data['zip_postal_code'] ?? '').toString();
      country = (data['country'] ?? '').toString();

      // identity
      final identityStatus = (data['identityStatus'] ?? '')
          .toString()
          .toLowerCase();
      final isCardVerified = (data['isCardVerified'] as bool?) ?? false;
      identityVerified = identityStatus == 'verified' || isCardVerified;

      _loadedOnce = true;

      isLoading = false;
      errorMessage = null;
      notifyListeners();
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = (resp is Map && resp['message'] != null)
          ? resp['message'].toString()
          : (e.message ?? 'Failed to load profile');

      isLoading = false;
      errorMessage = msg;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  // Keep your existing local edit method
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
