import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import 'widgets/common/auth_widgets.dart';

class AuthSuccessScreen extends ConsumerWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon / Illustration
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accentGreen,
                  size: 80,
                ),
              ),
              const SizedBox(height: 48),
              
              // Title
              Text(
                'auth.success.title'.tr(),
                textAlign: TextAlign.center,
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'auth.success.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.doveGray : AppColors.slate,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              
              // Action Button
              AuthPrimaryButton(
                label: 'auth.success.action'.tr(),
                onPressed: () {
                  context.go('/login');
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
