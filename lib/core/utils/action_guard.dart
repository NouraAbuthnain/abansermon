import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_button.dart';

class ActionGuard {
  /// Executes the [onVolunteerAccess] callback if the user is a Volunteer.
  /// If the user is a Guest, it prevents execution and shows the 
  /// "Become a Volunteer" promotional popup instead.
  static void execute({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onVolunteerAccess,
  }) {
    final auth = ref.read(authProvider);

    // Both role and a real user ID are required — a volunteer without a UID
    // can't be tracked as the active recorder in Firestore.
    if (auth.role == UserRole.volunteer && auth.userId != null) {
      onVolunteerAccess();
    } else {
      _showBecomeVolunteerPopup(context);
    }
  }

  static void _showBecomeVolunteerPopup(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: "Help Capture the Khutbah!",
      child: const _BecomeVolunteerPopup(),
    );
  }
}

class _BecomeVolunteerPopup extends StatelessWidget {
  const _BecomeVolunteerPopup();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final textColor = isDark ? Colors.white : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Graphic / Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icons/information.png',
              width: 48,
              height: 48,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            "Becoming a volunteer lets you record, transcribe, and contribute to the community directly from this feature.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.doveGray : AppColors.slate,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          AppButton(
            label: "Become a Volunteer",
            onPressed: () {
              Navigator.pop(context); // Dismiss Modal
              context.push('/signup'); // Send to Sign Up
            },
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: 8),
          
          AppButton(
            label: "Maybe Later",
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.tertiary,
          ),
        ],
      ),
    );
  }
}
