import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/features/profile/data/model/profile_model.dart';
import 'package:skudyx/features/profile/data/remote/profile_api.dart';

class ProfileController extends ChangeNotifier {
  final ProfileApi api;

  ProfileController({required this.api});

  // UI state
  bool isLoading = false;
  String? errorMessage;
  bool _loadedOnce = false;

  ProfileModel? _profileModel;
  ProfileModel? get profileModel => _profileModel;
  

  // ---------- Fields (initialised empty) ----------
  String firstName = '';
  String lastName = '';

  int profilePercent = 0;

  String phone = '';
  bool phoneVerified = false;

  String email = '';
  bool emailVerified = false;

  String addressLine1 = '';
  String addressLine2 = '';
  String city = '';
  String state = '';
  String zip = '';
  String country = '';

  bool identityVerified = false;
  void _resetFields() {
  firstName = '';
  lastName = '';
  profilePercent = 0;
  phone = '';
  phoneVerified = false;
  email = '';
  emailVerified = false;
  addressLine1 = '';
  addressLine2 = '';
  city = '';
  state = '';
  zip = '';
  country = '';
  identityVerified = false;
}

  // ---------- Derived getters ----------
  String get fullName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '—';
    return '$f $l'.trim();
  }

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
    //if (_loadedOnce && !force) return;
    if (isLoading) return;
    _profileModel = null;
     _resetFields(); 

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final body = await api.getProfile();

      // completion_percentage is often a top-level field
      if(body.isNotEmpty){

      }
      profilePercent =
          (body['completion_percentage'] as num?)?.toInt() ?? 0;

      final data = body['data'];
      log('Profile data loaded: $data');
      
      if (data is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/v1/users/profile'),
          error: 'Invalid profile response: data is missing',
        );
      }
      _profileModel = ProfileModel.fromJson(body);

      // Map every field from the response – fallback to empty string
      firstName = (data['first_name'] ?? '').toString();
      lastName = (data['last_name'] ?? '').toString();

      phone = (data['phone'] ?? '').toString();
      email = (data['email'] ?? '').toString();

      phoneVerified = (data['phoneVerified'] as bool?) ?? false;
      emailVerified = (data['emailVerified'] as bool?) ?? false;

      addressLine1 = (data['address'] ?? '').toString();
      addressLine2 = (data['address_line_2'] ?? '').toString();
      city = (data['city'] ?? '').toString();
      state = (data['state'] ?? '').toString();
      zip = (data['zip_postal_code'] ?? '').toString();
      country = (data['country'] ?? '').toString();

      // identity
      final identityStatus =
          (data['identityStatus'] ?? '').toString().toLowerCase();
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

  /// Local update (after editing) – keeps fields in sync
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
    // If phone changed, reset verification
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