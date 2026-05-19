import 'package:dio/dio.dart';

class DeviceDeliveryApi {
  final Dio dio;
  DeviceDeliveryApi({required this.dio});

  /// POST /api/v1/orders/delivery-details
  ///
  /// Provide the delivery details as a [data] map.
  /// For example:
  /// ```dart
  /// {
  ///   "address": "123 Main St",
  ///   "city": "New York",
  ///   "state": "NY",
  ///   "postal_code": "10001",
  ///   "phone": "+1234567890"
  /// }
  /// ```
  Future<Map<String, dynamic>> submitDeliveryDetails({
    required Map<String, dynamic> data,
  }) async {
    final res = await dio.post(
      '/api/v1/orders/delivery-details',
      data: data,
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;

    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ?? 'Failed to submit delivery details';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }

    return (body['data'] as Map<String, dynamic>);
  }
    Future<Map<String, dynamic>> getMyOrder() async {
    final res = await dio.get(
      '/api/v1/orders/my-order',
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ?? 'Failed to fetch order';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }

    return (body['data'] as Map<String, dynamic>);
  }

    /// POST /api/v1/users/update
  /// Updates user BLE device ID
  Future<Map<String, dynamic>> updateBleDeviceId({
    required String bleDeviceId,
  }) async {
    final res = await dio.post(
      '/api/v1/users/update',
      data: {
        'ble_device_id': bleDeviceId,
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final body = res.data;

    if (body is! Map<String, dynamic> || body['success'] != true) {
      final msg =
          (body is Map ? body['message'] : null) ??
          'Failed to update BLE device ID';

      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: msg.toString(),
      );
    }

    return (body['data'] as Map<String, dynamic>);
  }
}