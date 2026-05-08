// class AuthState {
//   final bool isAuthenticated;
//   final bool onboardingSeen;

//   final bool isLoading;
//   final String? errorMessage;

//   const AuthState({
//     required this.isAuthenticated,
//     required this.onboardingSeen,
//     this.isLoading = false,
//     this.errorMessage,
//   });

//   factory AuthState.loggedOut() =>
//       const AuthState(isAuthenticated: false, onboardingSeen: false);

//   AuthState copyWith({
//     bool? isAuthenticated,
//     bool? onboardingSeen,
//     bool? isLoading,
//     String? errorMessage,
//   }) {
//     return AuthState(
//       isAuthenticated: isAuthenticated ?? this.isAuthenticated,
//       onboardingSeen: onboardingSeen ?? this.onboardingSeen,
//       isLoading: isLoading ?? this.isLoading,
//       errorMessage: errorMessage,
//     );
//   }
// }

// lib/features/auth/presentation/controllers/auth_state.dart

class User {
  final String subscriptionPlan;
  final String? id;
  final String? email;
  final String? firstName;
  final String? lastName;

  User({
    required this.subscriptionPlan,
    this.id,
    this.email,
    this.firstName,
    this.lastName,
  });
}

class AuthState {
  final bool isAuthenticated;
  final bool onboardingSeen;
  final bool isLoading;
  final String? errorMessage;
  final User? user;

  const AuthState({
    required this.isAuthenticated,
    required this.onboardingSeen,
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  factory AuthState.loggedOut() => const AuthState(
    isAuthenticated: false,
    onboardingSeen: false,
    user: null,
  );

  AuthState copyWith({
    bool? isAuthenticated,
    bool? onboardingSeen,
    bool? isLoading,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}
