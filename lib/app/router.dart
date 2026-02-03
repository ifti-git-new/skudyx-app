import 'package:go_router/go_router.dart';
import 'package:skudyx/features/auth/presentation/screens/register_success_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_2_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_3_screen.dart';
import 'package:skudyx/features/onboarding/presentation/screens/instruction_4_screen.dart';

import '../core/navigation/app_routes.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/email_otp_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/cases/presentation/screens/case_details_screen.dart';
import '../features/cases/presentation/screens/case_list_screen.dart';
import '../features/delivery/presentation/screens/delivery_confirmation_screen.dart';
import '../features/delivery/presentation/screens/delivery_details_screen.dart';
import '../features/device/presentation/screens/device_screen.dart';
import '../features/emergency/presentation/screens/emergency_screen.dart';
import '../features/emergency/presentation/screens/test_report_screen.dart';
import '../features/emergency_contact/presentation/screens/emergency_contact_screen.dart';
import '../features/notifications_inbox/presentation/screens/notifications_inbox_screen.dart';
import '../features/onboarding/presentation/screens/instruction_1_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
// Screens (placeholders now)
import '../features/shell/presentation/screens/splash_screen.dart';
import '../features/subscription/presentation/screens/subscription_screen.dart';

class AppRouter {
  final AuthController auth;

  AppRouter({required this.auth});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,

    // redirect: (context, state) {
    //   final loc = state.matchedLocation;

    //   // allow splash
    //   if (loc == AppRoutes.splash) return null;

    //   final loggedIn = auth.state.isAuthenticated;
    //   final onboardingSeen = auth.state.onboardingSeen;

    //   final isAuthRoute =
    //       loc == AppRoutes.login ||
    //       loc == AppRoutes.register ||
    //       loc == AppRoutes.emailOtp ||
    //       loc == AppRoutes.forgotPassword;

    //   final isOnboardingRoute = loc.startsWith('/onboarding');

    //   if (!loggedIn && !isAuthRoute) return AppRoutes.login;

    //   if (loggedIn && !onboardingSeen && !isOnboardingRoute) {
    //     return AppRoutes.instruction1;
    //   }

    //   if (loggedIn && isAuthRoute) return AppRoutes.device;

    //   return null;
    // },

    //temporary updated redirect to allow register success screen access
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // allow splash
      if (loc == AppRoutes.splash) return null;

      final loggedIn = auth.state.isAuthenticated;
      final onboardingSeen = auth.state.onboardingSeen;

      // Routes allowed without login
      final isAuthFlowRoute =
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.emailOtp ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.registerSuccess; // ✅ ADD THIS

      final isOnboardingRoute = loc.startsWith('/onboarding');

      // Not logged in => only allow auth flow routes
      if (!loggedIn && !isAuthFlowRoute) return AppRoutes.login;

      // Logged in but onboarding not seen => force onboarding
      if (loggedIn && !onboardingSeen && !isOnboardingRoute) {
        return AppRoutes.instruction1;
      }

      // Logged in => block only the login/register/otp/forgot routes
      // (DO NOT block registerSuccess)
      final isLoginRelatedRoute =
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.emailOtp ||
          loc == AppRoutes.forgotPassword;

      if (loggedIn && isLoginRelatedRoute) return AppRoutes.device;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),

      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      GoRoute(
        path: AppRoutes.registerSuccess,
        builder: (_, __) => const RegisterSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailOtp,
        builder: (_, __) => const EmailOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

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

      GoRoute(path: AppRoutes.device, builder: (_, __) => const DeviceScreen()),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsInboxScreen(),
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.emergencyContact,
        builder: (_, __) => const EmergencyContactScreen(),
      ),

      GoRoute(
        path: AppRoutes.testReport,
        builder: (_, __) => const TestReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.emergency,
        builder: (_, __) => const EmergencyScreen(),
      ),

      GoRoute(
        path: AppRoutes.cases,
        builder: (_, __) => const CaseListScreen(),
      ),
      GoRoute(
        path: AppRoutes.caseDetails,
        builder: (_, __) => const CaseDetailsScreen(),
      ),
    ],
  );
}
