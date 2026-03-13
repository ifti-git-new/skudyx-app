import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;
  AuthApi({required this.dio});

  Future<({String accessToken, String refreshToken, Map<String, dynamic> user})>
  login({required String email, required String password}) async {
    // Render cold starts: retry once if timeout happens.
    const maxAttempts = 2;

    DioException? lastDioError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final res = await dio.post(
          '/api/v1/auth/login',
          data: {'email': email, 'password': password},
          options: Options(
            extra: const {'requiresAuth': false},

            // Make login more tolerant
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 40),
          ),
        );

        final body = res.data;
        if (body is! Map<String, dynamic>) {
          throw DioException(
            requestOptions: res.requestOptions,
            error: 'Invalid response format',
          );
        }

        if (body['success'] != true) {
          final msg = (body['message'] ?? 'Login failed').toString();
          throw DioException(
            requestOptions: res.requestOptions,
            response: res,
            error: msg,
          );
        }

        final data = (body['data'] as Map<String, dynamic>);
        final accessToken = (data['accessToken'] as String?) ?? '';
        final refreshToken = (data['refreshToken'] as String?) ?? '';
        final user =
            (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};

        if (accessToken.isEmpty || refreshToken.isEmpty) {
          throw DioException(
            requestOptions: res.requestOptions,
            response: res,
            error: 'Missing tokens from server',
          );
        }

        return (
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );
      } on DioException catch (e) {
        lastDioError = e;

        final isTimeout =
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout;

        // Retry only on timeout (first attempt)
        if (isTimeout && attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }

        rethrow;
      }
    }

    // Should never hit, but just in case:
    throw lastDioError ??
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          error: 'Login failed',
        );
  }

  /// Logout API call
  Future<void> logout() async {
    final res = await dio.post(
      '/api/v1/auth/logout',
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg = (body['message'] ?? 'Logout failed').toString();
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg,
      );
    }
  }
}
