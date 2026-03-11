import 'package:dio/dio.dart';

class CaseApi {
  final Dio dio;
  CaseApi({required this.dio});

  Future<Map<String, dynamic>> triggerCase({
    required double latitude,
    required double longitude,
    required bool isTest,
  }) async {
    final res = await dio.post(
      '/api/v1/cases/trigger',
      data: {'latitude': latitude, 'longitude': longitude, 'isTest': isTest},
      options: Options(extra: const {'requiresAuth': true}), // Token required
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg = (body?['message'] ?? 'Case creation failed').toString();
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg,
      );
    }

    return (body['data'] as Map<String, dynamic>);
  }
}
