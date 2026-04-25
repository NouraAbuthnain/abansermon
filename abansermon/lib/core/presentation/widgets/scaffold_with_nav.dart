import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NavBarHeight — InheritedWidget
//
// Broadcasts the exact pixel height of the bottom nav bar to any descendant
// (e.g. MosquesScreen). Child screens use this to:
//   • add bottom padding to scrollable content so it isn't hidden behind the bar
//   • give the FAB enough clearance so it sits above the bar
//
// Usage anywhere below ScaffoldWithNavBar in the tree:
//   final double navHeight = NavBarHeight.of(context);
// ─────────────────────────────────────────────────────────────────────────────
class NavBarHeight extends InheritedWidget {
  const NavBarHeight({
    super.key,
    required this.height,
    required super.child,
  });

  /// Total height of the bottom nav bar including the system bottom inset.
  final double height;

  static double of(BuildContext context) {
    final NavBarHeight? result =
        context.dependOnInheritedWidgetOfExactType<NavBarHeight>();
    // Graceful fallback — 80 dp covers most devices if the widget isn't found.
    return result?.height ?? 80.0;
  }

  @override
  bool updateShouldNotify(NavBarHeight old) => old.height != height;
}

// ─────────────────────────────────────────────────────────────────────────────
// ScaffoldWithNavBar
// ─────────────────────────────────────────────────────────────────────────────
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  // Fixed content height (icon + label + internal GNav padding).
  static const double _navContentHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = navigationShell.currentIndex;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // viewPadding.bottom is the hardware system inset.
    // It stays constant even when the keyboard is open (unlike padding).
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final double totalNavHeight = _navContentHeight + bottomInset;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return NavBarHeight(
      height: totalNavHeight,
      child: Scaffold(
        // extendBody: true — body renders behind the (opaque) nav bar.
        // This enables the FAB to be positioned above the nav bar
        // by Flutter's layout system when floatingActionButtonLocation
        // is set correctly on child Scaffolds.
        extendBody: true,

        // SafeArea on top only — the nav bar owns the bottom edge.
        body: SafeArea(
          bottom: false,
          child: navigationShell,
        ),

        bottomNavigationBar: _NavBar(
          selectedIndex: selectedIndex,
          isDark: isDark,
          bottomInset: bottomInset,
          navContentHeight: _navContentHeight,
          onTabChange: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavBar
// ─────────────────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.selectedIndex,
    required this.isDark,
    required this.bottomInset,
    required this.navContentHeight,
    required this.onTabChange,
  });

  final int selectedIndex;
  final bool isDark;
  final double bottomInset;
  final double navContentHeight;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    final Color navBg =
        isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;

    return Container(
      height: navContentHeight + bottomInset,
      decoration: BoxDecoration(
        color: navBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tab row ───────────────────────────────────────────────
          SizedBox(
            height: navContentHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GNav(
                selectedIndex: selectedIndex,
                onTabChange: onTabChange,
                gap: 6,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                color: AppColors.slate,
                activeColor: AppColors.accentGreen,
                tabBackgroundColor: AppColors.accentGreen.withValues(alpha: 0.10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                duration: const Duration(milliseconds: 350),
                tabBorderRadius: 12,
                iconSize: 22,
                tabs: [
                  _tab(
                    asset: 'assets/icons/home-page.png',
                    fallback: Icons.home_outlined,
                    label: 'nav.home'.tr(),
                    isActive: selectedIndex == 0,
                  ),
                  _tab(
                    asset: 'assets/icons/mosque.png',
                    fallback: Icons.mosque_outlined,
                    label: 'nav.mosques'.tr(),
                    isActive: selectedIndex == 1,
                  ),
                  _tab(
                    asset: 'assets/icons/menu.png',
                    fallback: Icons.grid_view_rounded,
                    label: 'nav.services'.tr(),
                    isActive: selectedIndex == 2,
                  ),
                  _tab(
                    asset: 'assets/icons/user.png',
                    fallback: Icons.person_outline,
                    label: 'nav.profile'.tr(),
                    isActive: selectedIndex == 3,
                  ),
                ],
              ),
            ),
          ),

          // ── System gesture / home-indicator spacer ────────────────
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }

  GButton _tab({
    required String asset,
    required IconData fallback,
    required String label,
    required bool isActive,
  }) {
    final Color iconColor =
        isActive ? AppColors.accentGreen : AppColors.slate;

    return GButton(
      icon: fallback,
      leading: Image.asset(
        asset,
        width: 22,
        height: 22,
        color: iconColor,
        errorBuilder: (_, __, ___) =>
            Icon(fallback, size: 22, color: iconColor),
      ),
      text: label,
    );
  }
}
