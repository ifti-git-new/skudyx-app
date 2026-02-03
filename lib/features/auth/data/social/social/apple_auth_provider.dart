import 'package:skudyx/features/auth/domain/entities/repositories/social_auth_provider.dart';
import 'package:skudyx/features/auth/domain/entities/social_auth_result.dart';

class AppleAuthProvider implements SocialAuthProvider {
  @override
  Future<SocialAuthResult> signIn() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const SocialAuthResult(
      provider: 'apple',
      accessToken: 'mock_apple_access',
      idToken: 'mock_apple_id',
    );
  }
}
