// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  Future<void> _showExitDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit SkudyX?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  int _indexFromLocation(String location) {
    // Devices tab includes all /device/* routes
    if (location.startsWith('/device')) return 0;

    // ✅ Emergency tab includes:
    // - /emergency-home
    // - /emergency/*
    // - /emergency-contact and /emergency-contact/*
    if (location.startsWith(AppRoutes.emergencyHome) ||
        location.startsWith('/emergency') ||
        location.startsWith('/emergency-contact')) {
      return 1;
    }

    if (location.startsWith(AppRoutes.settings)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;

    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.device);
        break;
      case 1:
        context.go(AppRoutes.emergencyHome);
        break;
      case 2:
        context.go(AppRoutes.settings);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        // If there's something to pop (like /device/connected), pop it first
        if (GoRouter.of(context).canPop()) {
          context.pop();
          return;
        }

        // Otherwise we are at a root route inside shell
        if (currentIndex == 0) {
          await _showExitDialog(context);
        } else {
          context.go(AppRoutes.device);
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => _onTap(context, i),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF081B4A),
          unselectedItemColor: const Color(0xFF6B7280),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.devices_outlined),
              label: 'Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.power_settings_new),
              label: 'Emergency',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
