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
}
