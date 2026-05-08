// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:skudyx/core/storage/app_prefs.dart';
// import 'package:skudyx/core/storage/auth_token_storage.dart';
// import 'package:skudyx/features/auth/data/remote/auth_api.dart';
// import 'package:skudyx/features/auth/domain/entities/repositories/social_auth_provider.dart';
// import 'package:skudyx/features/auth/presentation/controllers/auth_state.dart';

// class AuthController extends ChangeNotifier {
//   final AppPrefs prefs;
//   final AuthTokenStorage tokenStorage;
//   final AuthApi api;

//   final SocialAuthProvider googleAuthProvider;
//   final SocialAuthProvider appleAuthProvider;

//   AuthState state = AuthState.loggedOut();
//   bool _initialized = false;

//   bool isLoggingOut = false;

//   AuthController({
//     required this.prefs,
//     required this.tokenStorage,
//     required this.api,
//     required this.googleAuthProvider,
//     required this.appleAuthProvider,
//   });

//   Future<void> init() async {
//     if (_initialized) return;
//     _initialized = true;

//     final token = await tokenStorage.readAccessToken();
//     final isAuthed = token != null && token.isNotEmpty;

//     if (!isAuthed && prefs.loggedIn) {
//       await prefs.setLoggedIn(false);
//     }

//     state = AuthState(
//       isAuthenticated: isAuthed,
//       onboardingSeen: prefs.onboardingSeen,
//       isLoading: false,
//       errorMessage: null,
//     );
//     notifyListeners();
//   }

//   Future<bool> login({
//     required String email,
//     required String password,
//     required bool rememberMe,
//   }) async {
//     state = state.copyWith(isLoading: true, errorMessage: null);
//     notifyListeners();

//     try {
//       final res = await api.login(email: email.trim(), password: password);

//       await tokenStorage.saveTokens(
//         accessToken: res.accessToken,
//         refreshToken: res.refreshToken,
//         persist: rememberMe,
//       );

//       await prefs.setLoggedIn(true);

//       state = state.copyWith(
//         isAuthenticated: true,
//         isLoading: false,
//         errorMessage: null,
//       );
//       notifyListeners();
//       return true;
//     } on DioException catch (e) {
//       final msg = _dioMessage(e);
//       state = state.copyWith(isLoading: false, errorMessage: msg);
//       notifyListeners();
//       return false;
//     } catch (_) {
//       state = state.copyWith(
//         isLoading: false,
//         errorMessage: 'Something went wrong. Please try again.',
//       );
//       notifyListeners();
//       return false;
//     }
//   }

//   String _dioMessage(DioException e) {
//     final data = e.response?.data;
//     if (data is Map && data['message'] != null) {
//       return data['message'].toString();
//     }
//     if (e.error is String) return e.error.toString();

//     return switch (e.type) {
//       DioExceptionType.connectionTimeout ||
//       DioExceptionType.sendTimeout ||
//       DioExceptionType.receiveTimeout =>
//         'Connection timeout. Server may be waking up—please try again.',
//       DioExceptionType.connectionError => 'No internet / connection error.',
//       DioExceptionType.badResponse =>
//         'Login failed (${e.response?.statusCode ?? ''}).',
//       _ => 'Login failed. Please try again.',
//     };
//   }

//   Future<void> markOnboardingSeen() async {
//     await prefs.setOnboardingSeen(true);
//     state = state.copyWith(onboardingSeen: true);
//     notifyListeners();
//   }

//   /// Logout: calls API first, then clears local data
//   Future<void> logout() async {
//     if (isLoggingOut) return;

//     isLoggingOut = true;
//     notifyListeners();

//     try {
//       // Call backend logout API
//       await api.logout();
//     } catch (_) {
//       // Even if API fails, still clear local data (user should be able to logout)
//       // Optionally log the error for debugging
//       if (kDebugMode) {
//         // ignore: avoid_print
//         print('Logout API failed, but clearing local data anyway');
//       }
//     }

//     // Always clear local tokens and prefs
//     await tokenStorage.clear();
//     await prefs.clearAll();

//     state = AuthState.loggedOut();
//     isLoggingOut = false;
//     notifyListeners();
//   }

//   Future<void> signInWithGoogle() async {
//     await googleAuthProvider.signIn();
//     // TODO: exchange provider token with backend
//   }

//   Future<void> signInWithApple() async {
//     await appleAuthProvider.signIn();
//     // TODO: exchange provider token with backend
//   }
// }

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

    // Load user from shared prefs if available
    User? user;
    if (isAuthed) {
      final plan = prefs.subscriptionPlan;
      if (plan != null) {
        user = User(subscriptionPlan: plan);
      }
    }

    state = AuthState(
      isAuthenticated: isAuthed,
      onboardingSeen: prefs.onboardingSeen,
      isLoading: false,
      errorMessage: null,
      user: user,
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

      // Extract user data from login response
      // Adjust depending on your actual response structure
      final userData = res.user; // e.g., Map<String, dynamic>?
      final subscriptionPlan = userData?['subscriptionPlan'] ?? 'Basic';
      final user = User(subscriptionPlan: subscriptionPlan);

      // Save plan to shared prefs for persistence across app restarts
      await prefs.setSubscriptionPlan(subscriptionPlan);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        errorMessage: null,
        user: user,
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

  String _dioMessage(DioException e) {
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
        'Login failed (${e.response?.statusCode ?? ''}).',
      _ => 'Login failed. Please try again.',
    };
  }

  Future<void> markOnboardingSeen() async {
    await prefs.setOnboardingSeen(true);
    state = state.copyWith(onboardingSeen: true);
    notifyListeners();
  }

  Future<void> logout() async {
    if (isLoggingOut) return;

    isLoggingOut = true;
    notifyListeners();

    try {
      await api.logout();
    } catch (_) {
      if (kDebugMode) {
        print('Logout API failed, but clearing local data anyway');
      }
    }

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
