import 'package:flutter/foundation.dart';

import 'package:skudyx/core/storage/app_prefs.dart';
import 'package:skudyx/features/auth/domain/entities/repositories/social_auth_provider.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_state.dart';

class AuthController extends ChangeNotifier {
  final AppPrefs prefs;
  final SocialAuthProvider googleAuthProvider;
  final SocialAuthProvider appleAuthProvider;

  AuthState state = AuthState.loggedOut();
  bool _initialized = false;

  AuthController({
    required this.prefs,
    required this.googleAuthProvider,
    required this.appleAuthProvider,
  });

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    state = AuthState(
      isAuthenticated: prefs.loggedIn,
      onboardingSeen: prefs.onboardingSeen,
    );
    notifyListeners();
  }

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

  Future<void> signInWithGoogle() async {
    await googleAuthProvider.signIn();
    await mockLogin(isNewUser: false);
  }

  Future<void> signInWithApple() async {
    await appleAuthProvider.signIn();
    await mockLogin(isNewUser: false);
  }
}
