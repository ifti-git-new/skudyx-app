import 'package:go_router/go_router.dart';
import 'package:skudyx/core/navigation/app_routes.dart';
import 'package:skudyx/features/auth/presentation/controllers/auth_controller.dart';
import 'package:skudyx/features/auth/presentation/screens/email_otp_screen.dart';
import 'package:skudyx/features/auth/presentation/screens/forgot_password_screen.dart';
// Auth
import 'package:skudyx/features/auth/presentation/screens/login_screen.dart';
import 'package:skudyx/features/auth/presentation/screens/register_screen.dart';
import 'package:skudyx/features/auth/presentation/screens/register_success_screen.dart';
import 'package:skudyx/features/cases/presentation/screens/case_details_screen.dart';
import 'package:skudyx/features/delivery/presentation/screens/delivery_confirmation_screen.dart';
import 'package:skudyx/features/delivery/presentation/screens/delivery_details_screen.dart';
// Device flow screens
import 'package:skudyx/features/device/presentation/device_arrived_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_connected_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_list_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_searching_screen.dart';
import 'package:skudyx/features/emergency/presentation/screens/emergency_home_screen.dart';
// Emergency Contact
import 'package:skudyx/features/emergency_contact/presentation/screens/emergency_contact_form_screen.dart';
import 'package:skudyx/features/emergency_contact/presentation/screens/emergency_contact_screen.dart';
// Onboarding
import 'package:skudyx/features/onboarding/presentation/screens/instruction_1_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_2_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_3_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_4_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/cases/presentation/screens/case_history_screen.dart';
// Profile edit (no bottom nav)
import 'package:skudyx/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/identity/identity_capture_screen.dart';
// ✅ Identity verification flow (no bottom nav)
import 'package:skudyx/features/profile/presentation/screens/identity/identity_intro_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/identity/identity_select_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/identity/identity_success_screen.dart';
import 'package:skudyx/features/profile/presentation/screens/profile_screen.dart';
import 'package:skudyx/features/settings/presentation/screens/settings_screen.dart';
import 'package:skudyx/features/shell/presentation/screens/main_shell_screen.dart';
// Shell + tabs
import 'package:skudyx/features/shell/presentation/screens/splash_screen.dart';
// Subscription & delivery
import 'package:skudyx/features/subscription/presentation/screens/subscription_screen.dart';

class AppRouter {
  final AuthController auth;
  AppRouter({required this.auth});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,

    // debugLogDiagnostics: true,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // allow splash
      if (loc == AppRoutes.splash) return null;

      final loggedIn = auth.state.isAuthenticated;
      final onboardingSeen = auth.state.onboardingSeen;

      final prefs = auth.prefs;
      final isSubscribed = prefs.isSubscribed;
      final promptShown = prefs.subscriptionPromptShown;

      // Public auth flow routes (allowed when logged out)
      final isAuthFlowRoute =
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.emailOtp ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.registerSuccess;

      final isOnboardingRoute = loc.startsWith('/onboarding');

      // ✅ Treat all main app areas + subroutes as "main app"
      // (IMPORTANT: includes /identity/* and /profile/edit)
      final isShellAreaRoute =
          loc.startsWith('/device') ||
          loc.startsWith('/profile') ||
          loc.startsWith('/settings') ||
          loc.startsWith('/emergency-contact') ||
          loc.startsWith('/identity') ||
          loc.startsWith('/identity') ||
          loc == AppRoutes.emergencyHome;

      // 1) logged out -> only auth flow is allowed
      if (!loggedIn && !isAuthFlowRoute) return AppRoutes.login;

      // 2) logged in but onboarding not completed -> force onboarding routes only
      if (loggedIn && !onboardingSeen && !isOnboardingRoute) {
        return AppRoutes.instruction1;
      }

      // 3) After onboarding, show subscription ONCE if not subscribed
      if (loggedIn &&
          onboardingSeen &&
          isShellAreaRoute &&
          !isSubscribed &&
          !promptShown) {
        return AppRoutes.subscription;
      }

      // 4) logged in + onboarding done -> block going back to auth flow screens
      if (loggedIn && onboardingSeen && isAuthFlowRoute) {
        return AppRoutes.device;
      }

      return null;
    },

    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),

      // Auth
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailOtp,
        builder: (_, __) => const EmailOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerSuccess,
        builder: (_, __) => const RegisterSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.instruction1,
        builder: (_, __) => const Instruction1Screen(),
      ),
      GoRoute(
        path: AppRoutes.instruction2,
        builder: (_, __) => const Instruction2Screen(),
      ),
      GoRoute(
        path: AppRoutes.instruction3,
        builder: (_, __) => const Instruction3Screen(),
      ),
      GoRoute(
        path: AppRoutes.instruction4,
        builder: (_, __) => const Instruction4Screen(),
      ),

      // Subscription & delivery
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.deliveryDetails,
        builder: (_, __) => const DeliveryDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.deliveryConfirmation,
        builder: (_, __) => const DeliveryConfirmationScreen(),
      ),

      // Profile edit (outside shell -> no bottom nav)
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (_, __) => const EditProfileScreen(),
      ),

      // ✅ Identity Verification flow (outside shell -> no bottom nav)
      GoRoute(
        path: AppRoutes.identityIntro,
        builder: (_, __) => const IdentityIntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.identitySelect,
        builder: (_, __) => const IdentitySelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.identityCapture,
        builder: (_, __) => const IdentityCaptureScreen(),
      ),

      GoRoute(
        path: AppRoutes.settingsCaseHistory,
        builder: (_, __) => const CaseHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsCaseDetails,
        builder: (_, state) {
          final raw = state.pathParameters['caseId'] ?? '';
          final caseId = Uri.decodeComponent(raw);
          return CaseDetailsScreen(caseId: caseId);
        },
      ),

      GoRoute(
        path: AppRoutes.identitySuccess,
        builder: (_, __) => const IdentitySuccessScreen(),
      ),

      // ShellRoute (bottom nav visible)
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.device,
            builder: (_, __) => const DeviceScreen(),
          ),
          GoRoute(
            path: AppRoutes.emergencyHome,
            builder: (_, __) => const EmergencyHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),

          // Device flow screens under Devices tab
          GoRoute(
            path: AppRoutes.deviceArrived,
            builder: (_, __) => const DeviceArrivedScreen(),
          ),
          GoRoute(
            path: AppRoutes.deviceSearching,
            builder: (_, __) => const DeviceSearchingScreen(),
          ),
          GoRoute(
            path: AppRoutes.deviceList,
            builder: (_, __) => const DeviceListScreen(),
          ),
          GoRoute(
            path: AppRoutes.deviceConnected,
            builder: (_, __) => const DeviceConnectedScreen(),
          ),

          // Emergency Contact screens (under shell so bottom nav stays)
          GoRoute(
            path: AppRoutes.emergencyContact,
            builder: (_, __) => const EmergencyContactScreen(),
          ),
          GoRoute(
            path: AppRoutes.emergencyContactEdit,
            builder: (_, __) => const EmergencyContactFormScreen(),
          ),
        ],
      ),
    ],
  );
}
