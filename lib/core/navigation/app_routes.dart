abstract class AppRoutes {
  static const splash = '/splash';

  // Auth
  static const login = '/login';
  static const register = '/register';
  static const emailOtp = '/email-otp';
  static const registerSuccess = '/register-success';
  static const forgotPassword = '/forgot-password';

  // Onboarding
  static const instruction1 = '/onboarding/1';
  static const instruction2 = '/onboarding/2';
  static const instruction3 = '/onboarding/3';
  static const instruction4 = '/onboarding/4';

  // Subscription & Delivery
  static const subscription = '/subscription';
  static const deliveryDetails = '/delivery-details';
  static const deliveryConfirmation = '/delivery-confirmation';

  // Main tabs (bottom nav)
  static const device = '/device';
  static const emergencyHome = '/emergency-home';
  static const settings = '/settings';
  static const profile = '/profile';

  // Profile edit (no bottom nav)
  static const profileEdit = '/profile/edit';

  // Device flow (inside shell)
  static const deviceArrived = '/device/arrived';
  static const deviceSearching = '/device/searching';
  static const deviceList = '/device/list';
  static const deviceConnected = '/device/connected';

  // Emergency contact (inside shell)
  static const emergencyContact = '/emergency-contact';
  static const emergencyContactEdit = '/emergency-contact/edit';

  // Identity verification flow (no bottom nav)
  static const identityIntro = '/identity/intro';
  static const identitySelect = '/identity/select';
  static const identityCapture = '/identity/capture';
  static const identitySuccess = '/identity/success';

  // Settings sub-screens (keep under /settings so Settings tab stays selected)
  static const settingsCaseHistory = '/settings/case-history';
  static const settingsCaseDetails = '/settings/case-history/:caseId';
  static const settingsCompleteSetup = '/settings/complete-setup';
  static const settingsNotifications = '/settings/notifications';
  static const settingsHelpSupport = '/settings/help-support';
  static const settingsContactSupport =
      '/settings/help-support/contact'; // no bottom nav
  static const settingsFaqs = '/settings/faqs';
  static const settingsPrivacyPolicy = '/settings/privacy-policy';
  static const settingsTerms = '/settings/terms';
  static const completeSetup = '/complete-setup'; // Add this line
}
