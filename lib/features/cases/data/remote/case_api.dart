import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CaseApi {
  final Dio dio;
  final String baseUrl;

  CaseApi({
    required this.dio,
    this.baseUrl = 'https://skudyx-backend-thtu.onrender.com',
  });

  Future<Map<String, dynamic>> triggerCase({
    required double latitude,
    required double longitude,
    required bool isTest,
  }) async {
    try {
      final res = await dio.post(
        '$baseUrl/api/v1/cases/trigger',
        data: {'latitude': latitude, 'longitude': longitude, 'isTest': isTest},
        options: Options(extra: const {'requiresAuth': true}),
      );

      final body = res.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : 'Failed to trigger case';
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          error: msg,
        );
      }

      final data = body['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      if (kDebugMode) print('[CaseApi] triggerCase error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCaseDetails(String caseId) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/v1/cases/$caseId',
        options: Options(extra: const {'requiresAuth': true}),
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        return body['data'] ?? {};
      }
      return {};
    } catch (e) {
      if (kDebugMode) print('[CaseApi] getCaseDetails error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> updateLocation({
    required String caseId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final res = await dio.patch(
        '$baseUrl/api/v1/cases/update-location',
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

      final data = body['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      if (kDebugMode) print('[CaseApi] updateLocation error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateStatus({
    required String caseId,
    required String status,
    String? note,
  }) async {
    try {
      final res = await dio.patch(
        '$baseUrl/api/v1/cases/update-status',
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
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          error: 'Case not found. Please try again.',
        );
      } else if (e.response?.statusCode == 403) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          error: 'Permission denied. Please check your access rights.',
        );
      }
      if (kDebugMode) print('[CaseApi] updateStatus error: $e');
      rethrow;
    }
  }
}
