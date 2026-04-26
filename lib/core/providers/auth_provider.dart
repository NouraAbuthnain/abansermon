import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

enum UserRole { guest, volunteer }

class AuthState {
  final UserRole role;
  final bool isAuthenticated;
  final String? userId;

  const AuthState({
    required this.role,
    this.isAuthenticated = false,
    this.userId,
  });
}

/// In-memory signal — flipped by devLogin() so build() reacts immediately.
/// Seeded from SharedPreferences in main.dart so it survives restarts.
final devAuthOverrideProvider = StateProvider<bool>((ref) => false);

/// Streams the raw Firebase Auth user — the single source of truth.
final _firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // In-memory signal (flipped immediately on login/logout).
    final devOverride = ref.watch(devAuthOverrideProvider);

    // Persisted value — defensive fallback in case the override wasn't seeded.
    final devPersisted = ref.read(preferencesServiceProvider).isDevLoggedIn;

    if (devOverride || devPersisted) {
      return const AuthState(
        role: UserRole.volunteer,
        isAuthenticated: true,
        userId: 'dev_test_user',
      );
    }

    // Real Firebase auth path.
    final asyncUser = ref.watch(_firebaseUserProvider);
    return asyncUser.when(
      data: (user) => user != null
          ? AuthState(
              role: UserRole.volunteer,
              isAuthenticated: true,
              userId: user.uid,
            )
          : const AuthState(role: UserRole.guest, isAuthenticated: false),
      loading: () {
        final user = FirebaseAuth.instance.currentUser;
        return user != null
            ? AuthState(
                role: UserRole.volunteer,
                isAuthenticated: true,
                userId: user.uid,
              )
            : const AuthState(role: UserRole.guest, isAuthenticated: false);
      },
      error: (_, __) => const AuthState(role: UserRole.guest, isAuthenticated: false),
    );
  }

  /// Dev/testing login — persisted to SharedPreferences so it survives restarts.
  Future<void> devLogin() async {
    await ref.read(preferencesServiceProvider).setDevLoggedIn(true);
    ref.read(devAuthOverrideProvider.notifier).state = true;
  }

  Future<void> logout() async {
    await ref.read(preferencesServiceProvider).setDevLoggedIn(false);
    ref.read(devAuthOverrideProvider.notifier).state = false;
    await FirebaseAuth.instance.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Translates Riverpod auth state changes into a [Listenable] for GoRouter.
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}
