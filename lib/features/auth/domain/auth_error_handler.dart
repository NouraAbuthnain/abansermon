import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Translates Firebase Auth error codes into user-friendly,
/// localized i18n keys. This prevents raw technical messages
/// from ever reaching the volunteer's screen.
class AuthErrorHandler {
  /// Converts a [FirebaseAuthException] into a human-readable,
  /// localized error message string.
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'auth.errors.invalidPhoneNumber'.tr();
      case 'too-many-requests':
        return 'auth.errors.tooManyRequests'.tr();
      case 'quota-exceeded':
        return 'auth.errors.quotaExceeded'.tr();
      case 'session-expired':
        return 'auth.errors.sessionExpired'.tr();
      case 'invalid-verification-code':
        return 'auth.otp.invalidCode'.tr();
      case 'code-expired':
        return 'auth.otp.expiredCode'.tr();
      case 'network-request-failed':
        return 'auth.errors.networkError'.tr();
      case 'user-disabled':
        return 'auth.errors.accountDeactivated'.tr();
      default:
        return 'auth.errors.generic'.tr();
    }
  }

  /// Converts any generic [Exception] or [Error] into a
  /// human-readable localized message string.
  static String getGenericErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return 'auth.errors.networkError'.tr();
    }
    return 'auth.errors.generic'.tr();
  }
}
