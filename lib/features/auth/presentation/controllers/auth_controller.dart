import 'package:flutter/foundation.dart';
import '../../../../core/storage/app_prefs.dart';
import 'auth_state.dart';

class AuthController extends ChangeNotifier {
  final AppPrefs prefs;

  AuthState state = AuthState.loggedOut();
  bool _initialized = false;

  AuthController({required this.prefs});

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    state = AuthState(
      isAuthenticated: prefs.loggedIn,
      onboardingSeen: prefs.onboardingSeen,
    );
    notifyListeners();
  }

  // UI-only mock login (until APIs are ready)
  Future<void> mockLogin({required bool isNewUser}) async {
    await prefs.setLoggedIn(true);
    await prefs.setOnboardingSeen(!isNewUser);

    state = state.copyWith(isAuthenticated: true, onboardingSeen: !isNewUser);
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    await prefs.setOnboardingSeen(true);
    state = state.copyWith(onboardingSeen: true);
    notifyListeners();
  }

  Future<void> logout() async {
    await prefs.clearAll();
    state = AuthState.loggedOut();
    notifyListeners();
  }
}
