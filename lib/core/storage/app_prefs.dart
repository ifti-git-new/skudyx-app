import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  final SharedPreferences _sp;

  AppPrefs(this._sp);

  static Future<AppPrefs> create() async {
   
    final sp = await SharedPreferences.getInstance();
    await clearSecureStorageOnFreshInstall(sp);
    return AppPrefs(sp);
  }

static Future<void> clearSecureStorageOnFreshInstall(SharedPreferences sp) async {
  final sp = await SharedPreferences.getInstance();

  const installKey = 'app_install_id';

  final installId = sp.getString(installKey);

  // Fresh install detected
  if (installId == null) {
    const secureStorage = FlutterSecureStorage();

    // Clear iOS keychain / secure storage
    await secureStorage.deleteAll();

    // Save install marker
    await sp.setString(
      installKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

  // ---------------------------
  // Keys
  // ---------------------------
  static const _kLoggedIn = 'logged_in';
  static const _kOnboardingSeen = 'onboarding_seen';
  static const _kSubscriptionPromptShown = 'subscription_prompt_shown';
  static const _kIsSubscribed = 'is_subscribed';
  static const _kSubscriptionPlan = 'subscription_plan'; // ✅ NEW
  static const _kHasDeliveryDetails = 'has_delivery_details';
  static const _kDeviceArrived = 'device_arrived';
  static const _kEcAdded = 'ec_added';
  static const _kEcPhoneVerified = 'ec_phone_verified';
  static const _kEcEmailVerified = 'ec_email_verified';
  static const _kNotifSetupReminders = 'notif_setup_reminders';
  static const _kNotifDeliveryUpdates = 'notif_delivery_updates';
  static const _kNotifEmergencyAlerts = 'notif_emergency_alerts';
  static const _kNotifSystemAnnouncements = 'notif_system_announcements';

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

  String? get subscriptionPlan => _sp.getString(_kSubscriptionPlan); // ✅ NEW
  Future<void> setSubscriptionPlan(String v) => // ✅ NEW
      _sp.setString(_kSubscriptionPlan, v);

  // ---------------------------
  // Delivery
  // ---------------------------
  bool get hasDeliveryDetails => _sp.getBool(_kHasDeliveryDetails) ?? false;
  Future<void> setHasDeliveryDetails(bool v) =>
      _sp.setBool(_kHasDeliveryDetails, v);

  // ---------------------------
  // Device arrived
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
  bool get notifSetupReminders => _sp.getBool(_kNotifSetupReminders) ?? true;
  Future<void> setNotifSetupReminders(bool v) =>
      _sp.setBool(_kNotifSetupReminders, v);
  bool get notifDeliveryUpdates => _sp.getBool(_kNotifDeliveryUpdates) ?? true;
  Future<void> setNotifDeliveryUpdates(bool v) =>
      _sp.setBool(_kNotifDeliveryUpdates, v);
  bool get notifEmergencyAlerts => _sp.getBool(_kNotifEmergencyAlerts) ?? true;
  Future<void> setNotifEmergencyAlerts(bool v) =>
      _sp.setBool(_kNotifEmergencyAlerts, v);
  bool get notifSystemAnnouncements =>
      _sp.getBool(_kNotifSystemAnnouncements) ?? true;
  Future<void> setNotifSystemAnnouncements(bool v) =>
      _sp.setBool(_kNotifSystemAnnouncements, v);

  // ---------------------------
  // Clear all
  // ---------------------------
  Future<void> clearAll() async {
    await _sp.remove(_kLoggedIn);
    await _sp.remove(_kOnboardingSeen);
    await _sp.remove(_kSubscriptionPromptShown);
    await _sp.remove(_kIsSubscribed);
    await _sp.remove(_kSubscriptionPlan); // ✅ NEW
    await _sp.remove(_kHasDeliveryDetails);
    await _sp.remove(_kDeviceArrived);
    await _sp.remove(_kEcAdded);
    await _sp.remove(_kEcPhoneVerified);
    await _sp.remove(_kEcEmailVerified);
    await _sp.remove(_kNotifSetupReminders);
    await _sp.remove(_kNotifDeliveryUpdates);
    await _sp.remove(_kNotifEmergencyAlerts);
    await _sp.remove(_kNotifSystemAnnouncements);
  }
}
