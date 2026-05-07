import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final cardColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'profile.about.fullTitle'.tr() == 'profile.about.fullTitle' ? 'profile.about.aban'.tr() : 'profile.about.fullTitle'.tr(),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.about.subtitle'.tr(),
              style: textTheme.bodyLarge?.copyWith(
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Main Description Card
            _buildCard(
              context,
              cardColor,
              child: Text(
                'profile.about.description'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.7,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Mission Section
            _buildSectionTitle(context, 'profile.about.missionTitle'.tr()),
            const SizedBox(height: 12),
            _buildCard(
              context,
              cardColor,
              child: Text(
                'profile.about.missionText'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: textColor.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Features Section
            _buildSectionTitle(context, 'profile.about.featuresTitle'.tr()),
            const SizedBox(height: 16),
            _buildFeatureItem(context, 'assets/icons/translate.png', 'profile.about.features.f1'.tr()),
            _buildFeatureItem(context, 'assets/icons/audio.png', 'profile.about.features.f2'.tr()),
            _buildFeatureItem(context, 'assets/icons/cabinet.png', 'profile.about.features.f3'.tr()),
            _buildFeatureItem(context, 'assets/icons/user.png', 'profile.about.features.f4'.tr()),
            _buildFeatureItem(context, 'assets/icons/mosque.png', 'profile.about.features.f5'.tr()),
            
            const SizedBox(height: 48),

            // Footer
            Center(
              child: Text(
                'common.teamLabel'.tr(),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: subtitleColor.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
    );
  }

  Widget _buildCard(BuildContext context, Color color, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : AppStyles.cardShadow,
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: child,
    );
  }

  Widget _buildFeatureItem(BuildContext context, String iconPath, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              iconPath,
              width: 16,
              height: 16,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
