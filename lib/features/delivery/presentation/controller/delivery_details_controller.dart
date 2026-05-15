import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/features/delivery/data/model/order_details_model.dart';
import 'package:skudyx/features/delivery/data/remote/device_delivery_api.dart';

class DeviceDeliveryController extends ChangeNotifier {
  final DeviceDeliveryApi api;

  DeviceDeliveryController({required this.api});

  bool isSubmitting = false;
  String? errorMessage;
  bool isLoading = false;
  String? orderErrorMessage;

  OrderDetailsModel? _orderDetailsModel;
  OrderDetailsModel? get orderDetailsModel => _orderDetailsModel;

  /// Submit the delivery details.
  /// Returns `true` on success, `false` on failure (check [errorMessage]).
  Future<bool> submitDeliveryDetails(Map<String, dynamic> deliveryData) async {
    if (isSubmitting) return false;

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await api.submitDeliveryDetails(data: deliveryData);

      isSubmitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : (e.message ?? 'Failed to save delivery details');

      isSubmitting = false;
      errorMessage = msg;
      notifyListeners();
      return false;
    } catch (_) {
      isSubmitting = false;
      errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyOrder() async {
    // Reset to clean state
    _orderDetailsModel = null;
    if (isLoading) return;

    isLoading = true;
    orderErrorMessage = null;
    notifyListeners();

    try {
      final orderData = await api.getMyOrder();

      // Null / empty safety
      if (orderData == null || orderData.isEmpty) {
        isLoading = false;
        orderErrorMessage = 'No order found.';
        notifyListeners();
        return;
      }

      // Try to parse into model – wrap in its own try/catch to avoid breakage
      try {
        _orderDetailsModel = OrderDetailsModel.fromJson(orderData);
      } catch (parseError) {
        isLoading = false;
        orderErrorMessage = 'Failed to process order data.';
        notifyListeners();
        return;
      }

      isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : (e.message ?? 'Failed to load order');
      isLoading = false;
      orderErrorMessage = msg;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      orderErrorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }
}
