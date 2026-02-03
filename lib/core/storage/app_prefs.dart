import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  final SharedPreferences _sp;
  AppPrefs(this._sp);

  static Future<AppPrefs> create() async {
    final sp = await SharedPreferences.getInstance();
    return AppPrefs(sp);
  }

  static const _kLoggedIn = 'logged_in';
  static const _kOnboardingSeen = 'onboarding_seen';

  // Subscription gating (UI-only until API)
  static const _kSubscriptionPromptShown = 'subscription_prompt_shown';
  static const _kIsSubscribed = 'is_subscribed';

  // Delivery gating (UI-only until API)
  static const _kHasDeliveryDetails = 'has_delivery_details';

  bool get loggedIn => _sp.getBool(_kLoggedIn) ?? false;
  Future<void> setLoggedIn(bool v) => _sp.setBool(_kLoggedIn, v);

  bool get onboardingSeen => _sp.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen(bool v) => _sp.setBool(_kOnboardingSeen, v);

  bool get subscriptionPromptShown =>
      _sp.getBool(_kSubscriptionPromptShown) ?? false;
  Future<void> setSubscriptionPromptShown(bool v) =>
      _sp.setBool(_kSubscriptionPromptShown, v);

  bool get isSubscribed => _sp.getBool(_kIsSubscribed) ?? false;
  Future<void> setIsSubscribed(bool v) => _sp.setBool(_kIsSubscribed, v);

  bool get hasDeliveryDetails => _sp.getBool(_kHasDeliveryDetails) ?? false;
  Future<void> setHasDeliveryDetails(bool v) =>
      _sp.setBool(_kHasDeliveryDetails, v);

  Future<void> clearAll() async {
    await _sp.remove(_kLoggedIn);
    await _sp.remove(_kOnboardingSeen);
    await _sp.remove(_kSubscriptionPromptShown);
    await _sp.remove(_kIsSubscribed);
    await _sp.remove(_kHasDeliveryDetails);
  }
}
