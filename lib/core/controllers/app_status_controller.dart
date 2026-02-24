import 'package:flutter/foundation.dart';
import '../storage/app_prefs.dart';

class AppStatusController extends ChangeNotifier {
  final AppPrefs prefs;

  bool _isSubscribed;
  bool _hasDeliveryDetails;
  bool _deviceArrived;

  AppStatusController({required this.prefs})
    : _isSubscribed = prefs.isSubscribed,
      _hasDeliveryDetails = prefs.hasDeliveryDetails,
      _deviceArrived = prefs.deviceArrived;

  bool get isSubscribed => _isSubscribed;
  bool get hasDeliveryDetails => _hasDeliveryDetails;
  bool get deviceArrived => _deviceArrived;

  Future<void> setSubscribed(bool value) async {
    _isSubscribed = value;
    notifyListeners();
    await prefs.setIsSubscribed(value);
  }

  Future<void> setHasDeliveryDetails(bool value) async {
    _hasDeliveryDetails = value;
    notifyListeners();
    await prefs.setHasDeliveryDetails(value);
  }

  Future<void> setDeviceArrived(bool value) async {
    _deviceArrived = value;
    notifyListeners();
    await prefs.setDeviceArrived(value);
  }

  Future<void> refresh() async {
    _isSubscribed = prefs.isSubscribed;
    _hasDeliveryDetails = prefs.hasDeliveryDetails;
    _deviceArrived = prefs.deviceArrived;
    notifyListeners();
  }
}
