class AuthState {
  final bool isAuthenticated;
  final bool onboardingSeen;

  const AuthState({
    required this.isAuthenticated,
    required this.onboardingSeen,
  });

  factory AuthState.loggedOut() =>
      const AuthState(isAuthenticated: false, onboardingSeen: false);

  AuthState copyWith({bool? isAuthenticated, bool? onboardingSeen}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }
}
