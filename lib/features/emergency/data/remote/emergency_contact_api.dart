import 'package:dio/dio.dart';

class EmergencyContactApi {
  final Dio dio;
  EmergencyContactApi({required this.dio});

  Future<Map<String, dynamic>> saveEmergencyContact({
    required String contactName,
    required String phone,
    required String email,
    required String relation,
    required String address,
  }) async {
    final res = await dio.post(
      '/api/v1/emergency-contact/save',
      data: {
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'relation': relation,
        'address': address,
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ?? 'Failed to save contact';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }

    return (body['data'] as Map<String, dynamic>);
  }

Future<Map<String, dynamic>?> getEmergencyContact() async {
  try {
    final res = await dio.get(
      '/api/v1/emergency-contact/view',
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;

    if (body is! Map<String, dynamic> || body['success'] != true) {
      return null;
    }

    return body['data'] as Map<String, dynamic>;
  } on DioException catch (e) {
    // ✅ 404 means no contact — not an error
    if (e.response?.statusCode == 404) {
      return null;
    }

    rethrow; // Only real errors bubble up
  }
}

  Future<Map<String, dynamic>> verifyEmergencyContact({
    required String type,
    required String otp,
  }) async {
    final res = await dio.post(
      '/api/v1/emergency-contact/verify',
      data: {"type": type, "otp": otp},
      options: Options(extra: const {'requiresAuth': true}),
    );
    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ??
          'Failed to verify emergency contact';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }
    return (body['data'] as Map<String, dynamic>);
  }
}
