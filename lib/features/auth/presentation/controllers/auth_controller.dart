import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skudyx/core/storage/app_prefs.dart';
import 'package:skudyx/core/storage/auth_token_storage.dart';
import 'package:skudyx/features/auth/data/remote/auth_api.dart';
import 'package:skudyx/features/auth/domain/entities/repositories/social_auth_provider.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_state.dart';

class AuthController extends ChangeNotifier {
  final AppPrefs prefs;
  final AuthTokenStorage tokenStorage;
  final AuthApi api;

  final SocialAuthProvider googleAuthProvider;
  final SocialAuthProvider appleAuthProvider;

  AuthState state = AuthState.loggedOut();
  bool _initialized = false;

  bool isLoggingOut = false;
  String? otpErrorMessage ;

  AuthController({
    required this.prefs,
    required this.tokenStorage,
    required this.api,
    required this.googleAuthProvider,
    required this.appleAuthProvider,
  });

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final token = await tokenStorage.readAccessToken();
    final isAuthed = token != null && token.isNotEmpty;

    if (!isAuthed && prefs.loggedIn) {
      await prefs.setLoggedIn(false);
    }

    state = AuthState(
      isAuthenticated: isAuthed,
      onboardingSeen: prefs.onboardingSeen,
      isLoading: false,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final res = await api.login(email: email.trim(), password: password);

      await tokenStorage.saveTokens(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
        persist: rememberMe,
      );

      await prefs.setLoggedIn(true);
      await markOnboardingSeen();

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final msg = _dioMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: msg);
      notifyListeners();
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Register a new user and auto-login on success.
  /// Returns true on success, false on failure (check [state.errorMessage]).
 
Future<String?> register({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required String phone,
  String? address,
  String role = 'user',
}) async {
  state = state.copyWith(isLoading: true, errorMessage: null);
  notifyListeners();

  try {
    final res = await api.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      role: role,
      address: address,
      phone: phone,
    );

    state = state.copyWith(isLoading: false);
    notifyListeners();

    return res.email; // ✅ RETURN EMAIL HERE
  } on DioException catch (e) {
    final msg =
        _dioMessage(e, fallback: 'Registration failed. Please try again.');
    state = state.copyWith(isLoading: false, errorMessage: msg);
    notifyListeners();
    return null;
  } catch (_) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Something went wrong. Please try again.',
    );
    notifyListeners();
    return null;
  }
}


Future<bool> verifyUserOtp({
  required String email,
  required String otp,
}) async {
  try {
    otpErrorMessage = null;
    notifyListeners();

    final res = await api.verifyOtp(
      email: email,
      otp: otp,
    );

    /// ✅ SAVE TOKENS
    await tokenStorage.saveTokens(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
      persist: true,
    );

    /// ✅ Mark logged in
    await prefs.setLoggedIn(true);

    state = state.copyWith(
      isAuthenticated: true,
    );

    notifyListeners();

    return true;
  } on DioException catch (e) {
    otpErrorMessage =
        _dioMessage(e, fallback: 'Invalid or expired OTP');
    notifyListeners();
    return false;
  } catch (_) {
    otpErrorMessage = 'Something went wrong. Please try again.';
    notifyListeners();
    return false;
  }
}

String _dioMessage(DioException e, {String? fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.error is String) return e.error.toString();
 
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timeout. Server may be waking up—please try again.',
      DioExceptionType.connectionError => 'No internet / connection error.',
      DioExceptionType.badResponse =>
        '${fallback ?? 'Request failed'} (${e.response?.statusCode ?? ''}).',
      _ => fallback ?? 'Request failed. Please try again.',
    };
  }

  Future<void> markOnboardingSeen() async {
    await prefs.setOnboardingSeen(true);
    state = state.copyWith(onboardingSeen: true);
    notifyListeners();
  }

  /// Logout: calls API first, then clears local data
  Future<void> logout() async {
    if (isLoggingOut) return;

    isLoggingOut = true;
    notifyListeners();

    try {
      // Call backend logout API
      await api.logout();
    } catch (_) {
      // Even if API fails, still clear local data (user should be able to logout)
      // Optionally log the error for debugging
      if (kDebugMode) {
        // ignore: avoid_print
        print('Logout API failed, but clearing local data anyway');
      }
    }

    // Always clear local tokens and prefs
    await tokenStorage.clear();
    await prefs.clearAll();

    state = AuthState.loggedOut();
    isLoggingOut = false;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await googleAuthProvider.signIn();
    // TODO: exchange provider token with backend
  }

  Future<void> signInWithApple() async {
    await appleAuthProvider.signIn();
    // TODO: exchange provider token with backend
  }
}
