import 'package:skudyx/features/auth/domain/entities/repositories/social_auth_provider.dart';
import 'package:skudyx/features/auth/domain/entities/social_auth_result.dart';

class AppleAuthProvider implements SocialAuthProvider {
  @override
  Future<SocialAuthResult> signIn() async {
    // TODO: implement later using sign_in_with_apple
    await Future.delayed(const Duration(milliseconds: 300));
    return const SocialAuthResult(
      provider: 'apple',
      accessToken: 'mock_apple_access_token',
      idToken: 'mock_apple_id_token',
    );
  }
}
