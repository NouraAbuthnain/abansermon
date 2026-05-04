import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/mosque_discovery/presentation/mosque_list_screen.dart';
import '../../features/mosque_discovery/presentation/mosques_screen.dart';
import '../../features/mosque_discovery/presentation/mosque_detail_screen.dart';
import '../../features/mosque_discovery/presentation/mosque_map_screen.dart';
import '../../features/mosque_discovery/presentation/add_mosque_map_screen.dart';
import '../../features/mosque_discovery/presentation/add_mosque_search_screen.dart';
import '../../features/live_khutbah/presentation/live_khutbah_screen.dart';
import '../../features/auth/presentation/volunteer_login_screen.dart';
import '../../features/auth/presentation/volunteer_sign_up_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/auth_success_screen.dart';
import '../../features/volunteer_dashboard/presentation/capture_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../presentation/widgets/scaffold_with_nav.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final shellNavigatorMosquesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellMosques');
final shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: rootNavigatorKey,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isGuest = authState.role == UserRole.guest;

      // Define paths strictly reserved for volunteers
      final restrictedPaths = ['/capture', '/live'];

      final isAttemptingRestrictedPath = restrictedPaths.any(
        (path) => state.matchedLocation.startsWith(path),
      );

      // If a guest tries to navigate specifically to a dashboard, bounce them to login
      if (isAttemptingRestrictedPath && isGuest) {
        return '/login';
      }

      return null;
    },
    routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const VolunteerLoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const VolunteerSignUpScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpVerificationScreen(
          isSignUp: extra['isSignUp'] as bool? ?? false,
          phoneNumber: extra['phone'] as String? ?? '',
          verificationId: extra['verificationId'] as String? ?? '',
          confirmationResult: extra['confirmationResult'],
          fullName: extra['fullName'] as String? ?? '',
          documentType: extra['documentType'] as String? ?? '',
          documentNumber: extra['documentNumber'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/auth-success',
      builder: (context, state) => const AuthSuccessScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const MosqueListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellNavigatorMosquesKey,
          routes: [
            GoRoute(
              path: '/mosques',
              builder: (context, state) => const MosquesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellNavigatorProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    // Detail / full-screen routes — pinned to the root navigator so they
    // overlay the entire app (the bottom nav bar is part of the shell, not
    // these pages).
    GoRoute(
      path: '/mosque/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MosqueDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/map',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MosqueMapScreen(),
    ),
    GoRoute(
      path: '/add-mosque/map',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AddMosqueMapScreen(),
    ),
    GoRoute(
      path: '/add-mosque/search',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AddMosqueSearchScreen(),
    ),

    GoRoute(
      path: '/live/:sessionId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId']!;
        return LiveKhutbahScreen(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/capture/:mosqueId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final mosqueId = state.pathParameters['mosqueId'] ?? '';
        return CaptureScreen(mosqueId: mosqueId);
      },
    ),
    GoRoute(
      path: '/quran',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const QuranScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
}); // End of Provider
