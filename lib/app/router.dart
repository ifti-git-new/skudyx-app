import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skudyx/features/device/presentation/device_arrived_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_list_screen.dart';
import 'package:skudyx/features/device/presentation/screens/device_searching_screen.dart';

import '../core/navigation/app_routes.dart';
import '../core/storage/app_prefs.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

// Auth
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/email_otp_screen.dart';
import '../features/auth/presentation/screens/register_success_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';

// Onboarding
import '../features/onboarding/presentation/screens/instruction_1_screen.dart';
import '../features/onboarding/presentation/screens/instruction_2_screen.dart';
import '../features/onboarding/presentation/screens/instruction_3_screen.dart';
import '../features/onboarding/presentation/screens/instruction_4_screen.dart';

// Subscription & delivery
import '../features/subscription/presentation/screens/subscription_screen.dart';
import '../features/delivery/presentation/screens/delivery_details_screen.dart';
import '../features/delivery/presentation/screens/delivery_confirmation_screen.dart';

// Shell + tabs
import '../features/shell/presentation/screens/splash_screen.dart';
import '../features/shell/presentation/screens/main_shell_screen.dart';
import '../features/device/presentation/screens/device_screen.dart';
import '../features/emergency/presentation/screens/emergency_home_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

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

      // 1) logged out -> only auth flow
      if (!loggedIn && !isAuthFlowRoute) return AppRoutes.login;

      // 2) logged in but onboarding not seen -> force onboarding
      if (loggedIn && !onboardingSeen && !isOnboardingRoute)
        return AppRoutes.instruction1;

      // 3) After onboarding, show subscription ONCE if not subscribed
      // If user is trying to enter main app (tabs), but not subscribed and prompt not shown -> subscription
      final isMainTabRoute =
          loc == AppRoutes.device ||
          loc == AppRoutes.emergencyHome ||
          loc == AppRoutes.settings ||
          loc == AppRoutes.profile ||
          loc == AppRoutes.deviceArrived;

      if (loggedIn &&
          onboardingSeen &&
          isMainTabRoute &&
          !isSubscribed &&
          !promptShown) {
        return AppRoutes.subscription;
      }

      // 4) logged in and onboarding done -> block going back to auth flow screens
      if (loggedIn && onboardingSeen && isAuthFlowRoute)
        return AppRoutes.device;

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

      // Main shell (bottom nav) using a ShellRoute
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
        ],
      ),
    ],
  );
}
