import 'package:dio/dio.dart';

class SubscriptionApi {
  final Dio dio;

  SubscriptionApi({required this.dio});

  Future<Map<String, dynamic>> updateSubscription({
    required String plan, // "Basic" or "Premium"
  }) async {
    final res = await dio.patch(
      '/api/v1/users/subscription/update',
      data: {'subscriptionPlan': plan},
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Failed to update subscription';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg,
      );
    }
    return body;
  }
}
