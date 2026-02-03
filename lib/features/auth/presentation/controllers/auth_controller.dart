import 'package:flutter/foundation.dart';
import 'package:skudyx/features/auth/domain/entities/repositories/social_auth_provider.dart';

import '../../../../core/storage/app_prefs.dart';
import 'auth_state.dart';

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

  // UI-only mock login until API is integrated
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

  // -------- Social sign in (separate providers) --------

  Future<void> signInWithGoogle() async {
    final _ = await googleAuthProvider.signIn();

    // TODO: when API is ready:
    // send tokens to backend to create/login the user session
    // e.g. await authRepo.loginWithGoogle(_.idToken / _.accessToken)

    await mockLogin(isNewUser: false);
  }

  Future<void> signInWithApple() async {
    final _ = await appleAuthProvider.signIn();

    // TODO: when API is ready:
    // send tokens to backend to create/login the user session

    await mockLogin(isNewUser: false);
  }
}
