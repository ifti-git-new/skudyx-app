import '../../entities/social_auth_result.dart';

abstract class SocialAuthProvider {
  Future<SocialAuthResult> signIn();
}
