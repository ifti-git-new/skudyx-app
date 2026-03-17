import 'package:dio/dio.dart';

class ProfileUpdateApi {
  final Dio dio;
  ProfileUpdateApi({required this.dio});

  /// POST /api/v1/users/update
  ///
  /// Backend route uses multer (upload.single), so multipart is safest
  /// even when you are not uploading a file yet.
  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? address,
    String? addressLine2,
    String? city,
    String? state,
    String? zipPostalCode,
    String? country,
    String? emergencyPhone,
    String? idType,
    String? availabilityStatus,
    String? subscriptionPlan,
  }) async {
    final form = FormData.fromMap({
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'phone': phone.trim(),

      if (emergencyPhone != null && emergencyPhone.trim().isNotEmpty)
        'emergency_phone': emergencyPhone.trim(),

      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (addressLine2 != null && addressLine2.trim().isNotEmpty)
        'address_line_2': addressLine2.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
      if (zipPostalCode != null && zipPostalCode.trim().isNotEmpty)
        'zip_postal_code': zipPostalCode.trim(),
      if (country != null && country.trim().isNotEmpty)
        'country': country.trim(),

      if (idType != null && idType.trim().isNotEmpty) 'id_type': idType.trim(),
      if (availabilityStatus != null && availabilityStatus.trim().isNotEmpty)
        'availability_status': availabilityStatus.trim(),
      if (subscriptionPlan != null && subscriptionPlan.trim().isNotEmpty)
        'subscriptionPlan': subscriptionPlan.trim(),
    });

    final res = await dio.post(
      '/api/v1/users/update',
      data: form,
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ?? 'Failed to update profile';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }

    return body;
  }
}
