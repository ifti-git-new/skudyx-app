class SocialAuthResult {
  final String provider; // 'google' | 'apple'
  final String? accessToken;
  final String? idToken;

  const SocialAuthResult({
    required this.provider,
    this.accessToken,
    this.idToken,
  });
}
