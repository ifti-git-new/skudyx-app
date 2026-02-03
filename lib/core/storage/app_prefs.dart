import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  final SharedPreferences _sp;
  AppPrefs(this._sp);

  static Future<AppPrefs> create() async {
    final sp = await SharedPreferences.getInstance();
    return AppPrefs(sp);
  }

  // Keys
  static const _kLoggedIn = 'logged_in';
  static const _kOnboardingSeen = 'onboarding_seen';

  bool get loggedIn => _sp.getBool(_kLoggedIn) ?? false;
  Future<void> setLoggedIn(bool v) => _sp.setBool(_kLoggedIn, v);

  bool get onboardingSeen => _sp.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen(bool v) => _sp.setBool(_kOnboardingSeen, v);

  Future<void> clearAll() async {
    await _sp.remove(_kLoggedIn);
    await _sp.remove(_kOnboardingSeen);
  }
}
