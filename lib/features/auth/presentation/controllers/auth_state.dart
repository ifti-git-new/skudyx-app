class AuthState {
  final bool isAuthenticated;
  final bool onboardingSeen;

  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    required this.isAuthenticated,
    required this.onboardingSeen,
    this.isLoading = false,
    this.errorMessage,
  });

  factory AuthState.loggedOut() =>
      const AuthState(isAuthenticated: false, onboardingSeen: false);

  AuthState copyWith({
    bool? isAuthenticated,
    bool? onboardingSeen,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
