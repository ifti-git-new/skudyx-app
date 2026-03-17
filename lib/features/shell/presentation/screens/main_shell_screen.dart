// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    if (location.startsWith('/device')) return 0;
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
        // ✅ FIX: Open Emergency Contact screen (auto switches between Why/Overview)
        context.go(AppRoutes.emergencyContact);
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

    // Use LayoutBuilder to determine if we are on a large screen (e.g., Tablet)
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 600;

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (GoRouter.of(context).canPop()) {
              context.pop();
              return;
            }
            if (currentIndex == 0) {
              await _showExitDialog(context);
            } else {
              context.go(AppRoutes.device);
            }
          },
          child: Scaffold(
            // On tablets, we show a Row with a Sidebar (NavigationRail)
            body: Row(
              children: [
                if (isTablet)
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (i) => _onTap(context, i),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Colors.white,
                    selectedLabelTextStyle: const TextStyle(
                      color: Color(0xFF081B4A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                    destinations: [
                      _buildRailDestination(
                        'assets/icons/devices.svg',
                        'Devices',
                      ),
                      _buildRailDestination(
                        'assets/icons/emergency.svg',
                        'Emergency',
                      ),
                      _buildRailDestination(
                        'assets/icons/settings.svg',
                        'Settings',
                      ),
                      _buildRailDestination(
                        'assets/icons/profile.svg',
                        'Profile',
                      ),
                    ],
                  ),
                // Main Content Area
                Expanded(child: child),
              ],
            ),
            // On phones, we show the standard Bottom Bar
            bottomNavigationBar: isTablet
                ? null
                : BottomNavigationBar(
                    currentIndex: currentIndex,
                    onTap: (i) => _onTap(context, i),
                    type: BottomNavigationBarType.fixed,
                    selectedFontSize: 11,
                    unselectedFontSize: 11,
                    backgroundColor: Colors.white,
                    selectedItemColor: const Color(0xFF081B4A),
                    unselectedItemColor: const Color(0xFF6B7280),
                    items: [
                      _buildBottomItem('assets/icons/devices.svg', 'Devices'),
                      _buildBottomItem(
                        'assets/icons/emergency.svg',
                        'Emergency',
                      ),
                      _buildBottomItem('assets/icons/settings.svg', 'Settings'),
                      _buildBottomItem('assets/icons/profile.svg', 'Profile'),
                    ],
                  ),
          ),
        );
      },
    );
  }

  /// Helper for BottomNavigationBar items
  BottomNavigationBarItem _buildBottomItem(String path, String label) {
    return BottomNavigationBarItem(
      icon: _buildSvgIcon(path, false),
      activeIcon: _buildSvgIcon(path, true),
      label: label,
    );
  }

  /// Helper for NavigationRail items
  NavigationRailDestination _buildRailDestination(String path, String label) {
    return NavigationRailDestination(
      icon: _buildSvgIcon(path, false),
      selectedIcon: _buildSvgIcon(path, true),
      label: Text(label),
    );
  }

  /// Universal SVG Builder
  Widget _buildSvgIcon(String assetPath, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SvgPicture.asset(
        assetPath,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          isSelected ? const Color(0xFF081B4A) : const Color(0xFF6B7280),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
