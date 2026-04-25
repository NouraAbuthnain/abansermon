import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ActionGuard {
  /// Executes the [onVolunteerAccess] callback if the user is a Volunteer.
  /// If the user is a Guest, it prevents execution and shows the 
  /// "Become a Volunteer" promotional popup instead.
  static void execute({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onVolunteerAccess,
  }) {
    final userRole = ref.read(authProvider).role;

    if (userRole == UserRole.volunteer) {
      onVolunteerAccess();
    } else {
      _showBecomeVolunteerPopup(context);
    }
  }

  static void _showBecomeVolunteerPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _BecomeVolunteerPopup();
      },
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Graphic / Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic_external_on_rounded,
              size: 40,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            "Help Capture the Khutbah!",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          Text(
            "Becoming a volunteer lets you record, transcribe, and contribute to the community directly from this feature.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.8),
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss Modal
                context.push('/signup'); // Send to Sign Up
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Become a Volunteer",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: textColor.withOpacity(0.6),
            ),
            child: const Text(
              "Maybe Later",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }
}
