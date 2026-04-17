import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_back_button.dart';

class VolunteerLoginScreen extends StatelessWidget {
  const VolunteerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Header Image / Logo area
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                shape: BoxShape.circle,
                boxShadow: AppStyles.cardShadow,
              ),
              child: const Icon(Icons.mosque,
                  size: 40, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 24),
            Text(
              'auth.login.welcomeBack'.tr(),
              style: textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'auth.login.subtitle'.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 40),

            // Form container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Column(
                children: [
                  AppTextField(
                    labelText: 'auth.fields.fullName'.tr(),
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: 'auth.fields.phoneNumber'.tr(),
                    prefixIcon: Icons.phone_outlined,
                    hintText: 'auth.fields.phoneHint'.tr(),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: 'auth.fields.password'.tr(),
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, // TODO: Forget password
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'auth.login.forgotPassword'.tr(),
                        style: textTheme.labelLarge?.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'auth.login.submit'.tr(),
                    onPressed: () => context.go('/dashboard'),
                    variant: AppButtonVariant.primary,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.login.noAccount'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text(
                          'auth.login.createAccount'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
