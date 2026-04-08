import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../theme/app_theme.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.secondaryDarkBg
              : AppColors.pureWhite,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GNav(
            selectedIndex: selectedIndex,
            onTabChange: (int index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            gap: 8,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            color: AppColors.slate,
            activeColor: AppColors.accentGreen,
            tabBackgroundColor: AppColors.accentGreen.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            duration: const Duration(milliseconds: 400),
            tabBorderRadius: 8,
            iconSize: 24,
            tabs: [
              GButton(
                icon: Icons.home_outlined,
                leading: Image.asset('icons/home-page.png',
                    width: 24, height: 24,
                    color: selectedIndex == 0
                        ? AppColors.accentGreen
                        : AppColors.slate),
                text: 'Home',
              ),
              GButton(
                icon: Icons.mosque_outlined,
                leading: Image.asset('icons/mosque.png',
                    width: 24, height: 24,
                    color: selectedIndex == 1
                        ? AppColors.accentGreen
                        : AppColors.slate),
                text: 'Mosques',
              ),
              GButton(
                icon: Icons.menu,
                leading: Image.asset('icons/menu.png',
                    width: 24, height: 24,
                    color: selectedIndex == 2
                        ? AppColors.accentGreen
                        : AppColors.slate),
                text: 'Services',
              ),
              GButton(
                icon: Icons.person_outline,
                leading: Image.asset('icons/user.png',
                    width: 24, height: 24,
                    color: selectedIndex == 3
                        ? AppColors.accentGreen
                        : AppColors.slate),
                text: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
