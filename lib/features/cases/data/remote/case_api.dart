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
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Case creation failed';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg,
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Invalid response: missing data',
      );
    }

    return data;
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
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Location update failed';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg,
      );
    }
  }

  /// Update case status
  /// statuses: Created, Pending, In Progress, Escalated, Resolved, False, Unresolved
  Future<Map<String, dynamic>> updateStatus({
    required String caseId,
    required String status,
    String? note,
  }) async {
    final res = await dio.patch(
      '/api/v1/cases/update-status',
      data: {
        'case_id': caseId,
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Status update failed';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg,
      );
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) return data;

    // Sometimes backend may not return data—return empty map safely
    return <String, dynamic>{};
  }
}
