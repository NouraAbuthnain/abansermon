import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole {
  guest,
  volunteer,
}

class AuthState {
  final UserRole role;
  final bool isAuthenticated;

  const AuthState({
    required this.role,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserRole? role,
    bool? isAuthenticated,
  }) {
    return AuthState(
      role: role ?? this.role,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // For testing roles easily, you can swap this default state
    return const AuthState(role: UserRole.guest, isAuthenticated: false);
  }

  void loginAsVolunteer() {
    state = const AuthState(role: UserRole.volunteer, isAuthenticated: true);
  }

  void logout() {
    state = const AuthState(role: UserRole.guest, isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// A wrapper that translates Riverpod state changes into a [Listenable]
/// Specifically useful for binding to GoRouter's refreshListenable.
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen<AuthState>(
      authProvider,
      (_, __) {
        notifyListeners();
      },
    );
  }
}
