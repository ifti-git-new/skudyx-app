import 'package:skudyx/features/auth/domain/entities/repositories/social_auth_provider.dart';

import '../../domain/entities/social_auth_result.dart';

class GoogleAuthProvider implements SocialAuthProvider {
  @override
  Future<SocialAuthResult> signIn() async {
    // TODO: implement later using google_sign_in
    // For now: mock so UI flow works.
    await Future.delayed(const Duration(milliseconds: 300));
    return const SocialAuthResult(
      provider: 'google',
      accessToken: 'mock_google_access_token',
      idToken: 'mock_google_id_token',
    );
  }
}
