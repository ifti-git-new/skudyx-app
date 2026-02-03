import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/app_routes.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

// Screens (placeholders now)
import '../features/shell/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/email_otp_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';

import '../features/onboarding/presentation/screens/instruction_1_screen.dart';
import '../features/device/presentation/screens/device_screen.dart';

import '../features/subscription/presentation/screens/subscription_screen.dart';
import '../features/delivery/presentation/screens/delivery_details_screen.dart';
import '../features/delivery/presentation/screens/delivery_confirmation_screen.dart';

import '../features/notifications_inbox/presentation/screens/notifications_inbox_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

import '../features/emergency_contact/presentation/screens/emergency_contact_screen.dart';
import '../features/emergency/presentation/screens/test_report_screen.dart';
import '../features/emergency/presentation/screens/emergency_screen.dart';

import '../features/cases/presentation/screens/case_list_screen.dart';
import '../features/cases/presentation/screens/case_details_screen.dart';

class AppRouter {
  final AuthController auth;

  AppRouter({required this.auth});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // allow splash
      if (loc == AppRoutes.splash) return null;

      final loggedIn = auth.state.isAuthenticated;
      final onboardingSeen = auth.state.onboardingSeen;

      final isAuthRoute =
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.emailOtp ||
          loc == AppRoutes.forgotPassword;

      final isOnboardingRoute = loc.startsWith('/onboarding');

      if (!loggedIn && !isAuthRoute) return AppRoutes.login;

      if (loggedIn && !onboardingSeen && !isOnboardingRoute) {
        return AppRoutes.instruction1;
      }

      if (loggedIn && isAuthRoute) return AppRoutes.device;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),

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
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: AppRoutes.instruction1,
        builder: (_, __) => const Instruction1Screen(),
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
