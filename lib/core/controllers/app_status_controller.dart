import 'package:flutter/foundation.dart';
import '../storage/app_prefs.dart';

class AppStatusController extends ChangeNotifier {
  final AppPrefs prefs;

  bool _isSubscribed;
  bool _hasDeliveryDetails;

  AppStatusController({required this.prefs})
    : _isSubscribed = prefs.isSubscribed,
      _hasDeliveryDetails = prefs.hasDeliveryDetails;

  bool get isSubscribed => _isSubscribed;
  bool get hasDeliveryDetails => _hasDeliveryDetails;

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

  Future<void> refresh() async {
    _isSubscribed = prefs.isSubscribed;
    _hasDeliveryDetails = prefs.hasDeliveryDetails;
    notifyListeners();
  }
}
