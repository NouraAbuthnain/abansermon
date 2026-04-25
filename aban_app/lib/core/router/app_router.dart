import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/mosque_discovery/presentation/mosque_list_screen.dart';
import '../../features/mosque_discovery/presentation/mosques_screen.dart';
import '../../features/mosque_discovery/presentation/mosque_detail_screen.dart';
import '../../features/mosque_discovery/presentation/mosque_map_screen.dart';
import '../../features/live_khutbah/presentation/live_khutbah_screen.dart';
import '../../features/auth/presentation/volunteer_login_screen.dart';
import '../../features/auth/presentation/volunteer_sign_up_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/auth_success_screen.dart';
import '../../features/volunteer_dashboard/presentation/manage_capture_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../../features/archive/presentation/archive_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../presentation/widgets/scaffold_with_nav.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final shellNavigatorMosquesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellMosques');
final shellNavigatorServicesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellServices');
final shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  navigatorKey: rootNavigatorKey,
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
        final phone = state.extra as String? ?? 'auth.fields.phoneHint'.tr();
        return OtpVerificationScreen(phoneNumber: phone);
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
          navigatorKey: shellNavigatorServicesKey,
          routes: [
            GoRoute(
              path: '/services',
              builder: (context, state) => const ServicesScreen(),
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
    // Other routes
    GoRoute(
      path: '/mosque/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MosqueDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MosqueMapScreen(),
    ),
    GoRoute(
      path: '/archive',
      builder: (context, state) => const ArchiveScreen(),
    ),
    GoRoute(
      path: '/live/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId']!;
        return LiveKhutbahScreen(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const ManageCaptureScreen(),
    ),
    GoRoute(
      path: '/quran',
      builder: (context, state) => const QuranScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
