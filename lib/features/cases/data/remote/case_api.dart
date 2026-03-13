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
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ?? 'Case creation failed';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }

    return (body['data'] as Map<String, dynamic>);
  }

  /// Backend expects PATCH (not POST)
  Future<void> updateLocation({
    required String caseId,
    required double latitude,
    required double longitude,
  }) async {
    final res = await dio.patch(
      '/api/v1/cases/update-location',
      data: {'case_id': caseId, 'latitude': latitude, 'longitude': longitude},
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ?? 'Location update failed';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }
  }
}
