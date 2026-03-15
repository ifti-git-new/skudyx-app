import 'package:dio/dio.dart';

class ProfileApi {
  final Dio dio;
  ProfileApi({required this.dio});

  /// GET /api/v1/users/profile  (token required)
  Future<Map<String, dynamic>> getProfile() async {
    final res = await dio.get(
      '/api/v1/users/profile',
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ?? 'Failed to load profile';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }

    return body;
  }
}
