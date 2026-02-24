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
  static const profileEdit = '/profile/edit';

  // Other screens (non-tab)
  static const notifications = '/notifications';
  static const emergencyContact = '/emergency-contact';
  static const emergencyContactEdit = '/emergency-contact/edit';

  static const testReport = '/test-report';
  static const emergency = '/emergency';

  static const cases = '/cases';
  static const caseDetails = '/cases/details';
  static const deviceArrived = '/device/arrived';
  static const deviceSearching = '/device/searching';
  static const deviceList = '/device/list';
  static const deviceConnected = '/device/connected';

  // Identity verification flow
  static const identityIntro = '/identity/intro';
  static const identitySelect = '/identity/select';
  static const identityCapture = '/identity/capture';
  static const identityProcessing = '/identity/processing';
  static const identitySuccess = '/identity/success';

  //case history
  static const settingsCaseHistory = '/settings/case-history';
  static const settingsCaseDetails = '/settings/case-history/:caseId';
  static const settingsCompleteSetup = '/settings/complete-setup';
}
