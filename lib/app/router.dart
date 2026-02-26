import 'package:go_router/go_router.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_controller.dart';

// Auth
import 'package:skudyx/features/auth/presentation/screens/login_screen.dart';
import 'package:skudyx/features/auth/presentation/screens/register_screen.dart';
import 'package:skudyx/features/auth/presentation/screens/email_otp_screen.dart';
import 'package:skudyx/features/auth/presentation/screens/register_success_screen.dart';
import 'package:skudyx/features/auth/presentation/screens/forgot_password_screen.dart';

// Onboarding
import 'package:skudyx/features/onboarding/presentation/screens/instruction_1_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_2_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_3_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_4_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/cases/presentation/screens/case_history_screen.dart';

// Subscription & delivery
import 'package:skudyx/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:skudyx/features/delivery/presentation/screens/delivery_details_screen.dart';
import 'package:skudyx/features/delivery/presentation/screens/delivery_confirmation_screen.dart';

// Shell + tabs
import 'package:skudyx/features/shell/presentation/screens/splash_screen.dart';
import 'package:skudyx/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_screen.dart';
import 'package:skudyx/features/emergency/presentation/screens/emergency_home_screen.dart';
import 'package:skudyx/features/settings/presentation/screens/settings_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/profile_screen.dart';

// Profile edit (no bottom nav)
import 'package:skudyx/features/profile/presentation/screens/edit_profile_screen.dart';

// Identity verification (no bottom nav)
import 'package:skudyx/features/profile/presentation/screens/identity/identity_intro_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/identity/identity_select_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/identity/identity_capture_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/identity/identity_success_screen.dart';

// Device flow screens (inside shell)
import 'package:skudyx/features/device/presentation/device_arrived_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_searching_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_list_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_connected_screen.dart';

// Emergency Contact (inside shell)
import 'package:skudyx/features/emergency_contact/presentation/screens/emergency_contact_screen.dart';
import 'package:skudyx/features/emergency_contact/presentation/screens/emergency_contact_form_screen.dart';

// Settings sub screens
import 'package:skudyx/features/settings/presentation/screens/complete_setup_screen.dart';
import 'package:skudyx/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:skudyx/features/settings/presentation/screens/help_support_screen.dart';
import 'package:skudyx/features/settings/presentation/screens/contact_support_screen.dart'; // no bottom nav
import 'package:skudyx/features/settings/presentation/screens/faqs_screen.dart';
import 'package:skudyx/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:skudyx/features/settings/presentation/screens/terms_conditions_screen.dart';

// Cases (✅ FIXED IMPORT PATH)
import 'package:skudyx/features/cases/presentation/screens/case_details_screen.dart';

class AppRouter {
  final AuthController auth;
  AppRouter({required this.auth});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,

    // debugLogDiagnostics: true,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (loc == AppRoutes.splash) return null;

      final loggedIn = auth.state.isAuthenticated;
      final onboardingSeen = auth.state.onboardingSeen;

      final prefs = auth.prefs;
      final isSubscribed = prefs.isSubscribed;
      final promptShown = prefs.subscriptionPromptShown;

      final isAuthFlowRoute =
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.emailOtp ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.registerSuccess;

      final isOnboardingRoute = loc.startsWith('/onboarding');

      // treat all app areas as "main app"
      final isMainAppRoute =
          loc.startsWith('/device') ||
          loc.startsWith('/profile') ||
          loc.startsWith('/settings') ||
          loc.startsWith('/emergency-contact') ||
          loc.startsWith('/identity') ||
          loc == AppRoutes.emergencyHome;

      if (!loggedIn && !isAuthFlowRoute) return AppRoutes.login;

      if (loggedIn && !onboardingSeen && !isOnboardingRoute) {
        return AppRoutes.instruction1;
      }

      if (loggedIn &&
          onboardingSeen &&
          isMainAppRoute &&
          !isSubscribed &&
          !promptShown) {
        return AppRoutes.subscription;
      }

      if (loggedIn && onboardingSeen && isAuthFlowRoute) {
        return AppRoutes.device;
      }

      return null;
    },

    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),

      // Auth
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailOtp,
        builder: (_, _) => const EmailOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerSuccess,
        builder: (_, _) => const RegisterSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.instruction1,
        builder: (_, _) => const Instruction1Screen(),
      ),
      GoRoute(
        path: AppRoutes.instruction2,
        builder: (_, _) => const Instruction2Screen(),
      ),
      GoRoute(
        path: AppRoutes.instruction3,
        builder: (_, _) => const Instruction3Screen(),
      ),
      GoRoute(
        path: AppRoutes.instruction4,
        builder: (_, _) => const Instruction4Screen(),
      ),

      // Subscription & Delivery
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, _) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.deliveryDetails,
        builder: (_, _) => const DeliveryDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.deliveryConfirmation,
        builder: (_, _) => const DeliveryConfirmationScreen(),
      ),

      // Profile edit (no bottom nav)
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (_, _) => const EditProfileScreen(),
      ),

      // Identity flow (no bottom nav)
      GoRoute(
        path: AppRoutes.identityIntro,
        builder: (_, _) => const IdentityIntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.identitySelect,
        builder: (_, _) => const IdentitySelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.identityCapture,
        builder: (_, _) => const IdentityCaptureScreen(),
      ),
      GoRoute(
        path: AppRoutes.identitySuccess,
        builder: (_, _) => const IdentitySuccessScreen(),
      ),

      // Contact Support (no bottom nav)
      GoRoute(
        path: AppRoutes.settingsContactSupport,
        builder: (_, _) => const ContactSupportScreen(),
      ),

      // Shell (bottom nav visible)
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.device,
            builder: (_, _) => const DeviceScreen(),
          ),
          GoRoute(
            path: AppRoutes.emergencyHome,
            builder: (_, _) => const EmergencyHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),

          // Device flow
          GoRoute(
            path: AppRoutes.deviceArrived,
            builder: (_, _) => const DeviceArrivedScreen(),
          ),
          GoRoute(
            path: AppRoutes.deviceSearching,
            builder: (_, _) => const DeviceSearchingScreen(),
          ),
          GoRoute(
            path: AppRoutes.deviceList,
            builder: (_, _) => const DeviceListScreen(),
          ),
          GoRoute(
            path: AppRoutes.deviceConnected,
            builder: (_, _) => const DeviceConnectedScreen(),
          ),

          // Emergency Contact
          GoRoute(
            path: AppRoutes.emergencyContact,
            builder: (_, _) => const EmergencyContactScreen(),
          ),
          GoRoute(
            path: AppRoutes.emergencyContactEdit,
            builder: (_, _) => const EmergencyContactFormScreen(),
          ),

          // Settings sub screens (bottom nav stays, Settings tab stays selected)
          GoRoute(
            path: AppRoutes.settingsCompleteSetup,
            builder: (_, _) => const CompleteSetupScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsNotifications,
            builder: (_, _) => const NotificationPreferencesScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsHelpSupport,
            builder: (_, _) => const HelpSupportScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsFaqs,
            builder: (_, _) => const FaqsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsPrivacyPolicy,
            builder: (_, _) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsTerms,
            builder: (_, _) => const TermsConditionsScreen(),
          ),

          // Case history under settings
          GoRoute(
            path: AppRoutes.settingsCaseHistory,
            builder: (_, _) => const CaseHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsCaseDetails,
            builder: (_, state) {
              final raw = state.pathParameters['caseId'] ?? '';
              final caseId = Uri.decodeComponent(raw);
              return CaseDetailsScreen(caseId: caseId);
            },
          ),
        ],
      ),
    ],
  );
}
