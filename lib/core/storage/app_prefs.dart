import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  final SharedPreferences _sp;
  AppPrefs(this._sp);

  static Future<AppPrefs> create() async {
    final sp = await SharedPreferences.getInstance();
    return AppPrefs(sp);
  }

  // ---------------------------
  // Keys
  // ---------------------------
  static const _kLoggedIn = 'logged_in';
  static const _kOnboardingSeen = 'onboarding_seen';

  // Subscription gating (UI-only until API)
  static const _kSubscriptionPromptShown = 'subscription_prompt_shown';
  static const _kIsSubscribed = 'is_subscribed';

  // Delivery gating (UI-only until API)
  static const _kHasDeliveryDetails = 'has_delivery_details';

  // Device delivery state (UI-only until API)
  static const _kDeviceArrived = 'device_arrived';

  // Emergency Contact (UI-only until API)
  static const _kEcAdded = 'ec_added';
  static const _kEcPhoneVerified = 'ec_phone_verified';
  static const _kEcEmailVerified = 'ec_email_verified';

  // ---------------------------
  // Auth
  // ---------------------------
  bool get loggedIn => _sp.getBool(_kLoggedIn) ?? false;
  Future<void> setLoggedIn(bool v) => _sp.setBool(_kLoggedIn, v);

  bool get onboardingSeen => _sp.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen(bool v) => _sp.setBool(_kOnboardingSeen, v);

  // ---------------------------
  // Subscription
  // ---------------------------
  bool get subscriptionPromptShown =>
      _sp.getBool(_kSubscriptionPromptShown) ?? false;
  Future<void> setSubscriptionPromptShown(bool v) =>
      _sp.setBool(_kSubscriptionPromptShown, v);

  bool get isSubscribed => _sp.getBool(_kIsSubscribed) ?? false;
  Future<void> setIsSubscribed(bool v) => _sp.setBool(_kIsSubscribed, v);

  // ---------------------------
  // Delivery
  // ---------------------------
  bool get hasDeliveryDetails => _sp.getBool(_kHasDeliveryDetails) ?? false;
  Future<void> setHasDeliveryDetails(bool v) =>
      _sp.setBool(_kHasDeliveryDetails, v);

  // ---------------------------
  // Device arrived (after shipping / delivery)
  // ---------------------------

  bool get deviceArrived => _sp.getBool(_kDeviceArrived) ?? false;
  Future<void> setDeviceArrived(bool v) => _sp.setBool(_kDeviceArrived, v);

  // ---------------------------
  // Emergency Contact
  // ---------------------------
  bool get ecAdded => _sp.getBool(_kEcAdded) ?? false;
  Future<void> setEcAdded(bool v) => _sp.setBool(_kEcAdded, v);

  bool get ecPhoneVerified => _sp.getBool(_kEcPhoneVerified) ?? false;
  Future<void> setEcPhoneVerified(bool v) => _sp.setBool(_kEcPhoneVerified, v);

  bool get ecEmailVerified => _sp.getBool(_kEcEmailVerified) ?? false;
  Future<void> setEcEmailVerified(bool v) => _sp.setBool(_kEcEmailVerified, v);

  // ---------------------------
  // Clear all
  // ---------------------------
  Future<void> clearAll() async {
    await _sp.remove(_kLoggedIn);
    await _sp.remove(_kOnboardingSeen);

    await _sp.remove(_kSubscriptionPromptShown);
    await _sp.remove(_kIsSubscribed);

    await _sp.remove(_kHasDeliveryDetails);
    await _sp.remove(_kDeviceArrived);

    await _sp.remove(_kEcAdded);
    await _sp.remove(_kEcPhoneVerified);
    await _sp.remove(_kEcEmailVerified);
  }
}
