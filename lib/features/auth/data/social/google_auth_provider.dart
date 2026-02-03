import '../../domain/entities/social_auth_result.dart';
import '../../domain/entities/repositories/social_auth_provider.dart';

class GoogleAuthProvider implements SocialAuthProvider {
  @override
  Future<SocialAuthResult> signIn() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const SocialAuthResult(
      provider: 'google',
      accessToken: 'mock_google_access',
      idToken: 'mock_google_id',
    );
  }
}
