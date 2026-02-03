import 'package:skudyx/features/auth/domain/entities/social_auth_result.dart'
    show SocialAuthResult;

abstract class SocialAuthProvider {
  Future<SocialAuthResult> signIn();
}
