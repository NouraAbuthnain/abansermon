import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';

class AuthSuccessModal extends StatelessWidget {
  const AuthSuccessModal({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      backgroundColor: AppColors.pureWhite,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Account Created Successfully!',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Subtitle
            Text(
              'Your volunteer account has been successfully verified. You can now log in and start using ABAN.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            
            // Actions
            AppButton(
              label: 'Log in',
              onPressed: () => context.go('/dashboard'),
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Continue as Guest',
              onPressed: () => context.go('/home'),
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
