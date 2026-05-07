import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'aban.sermon@gmail.com',
      queryParameters: {
        'subject': 'Support Request - Aban App',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'profile.help.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              'profile.help.subtitle'.tr(),
              style: textTheme.bodyLarge?.copyWith(
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // FAQs Section
            Text(
              'profile.help.faqTitle'.tr(),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(context, 'profile.help.faq.q1'.tr(), 'profile.help.faq.a1'.tr()),
            _buildFAQItem(context, 'profile.help.faq.q2'.tr(), 'profile.help.faq.a2'.tr()),
            _buildFAQItem(context, 'profile.help.faq.q3'.tr(), 'profile.help.faq.a3'.tr()),
            _buildFAQItem(context, 'profile.help.faq.q4'.tr(), 'profile.help.faq.a4'.tr()),
            _buildFAQItem(context, 'profile.help.faq.q5'.tr(), 'profile.help.faq.a5'.tr()),

            const SizedBox(height: 40),

            // Contact Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.help.contactTitle'.tr(),
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'profile.help.contactText'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildContactInfo(
                    context,
                    Icons.email_outlined,
                    'profile.help.emailLabel'.tr(),
                    'profile.help.email'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    context,
                    Icons.access_time_outlined,
                    'profile.help.responseTime'.tr(),
                    '',
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'profile.help.cta'.tr(),
                    onPressed: _launchEmail,
                    variant: AppButtonVariant.primary,
                    // White button on gradient
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : AppColors.doveGray.withOpacity(0.1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.topLeft,
          iconColor: AppColors.primaryTeal,
          collapsedIconColor: AppColors.slate,
          children: [
            Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.doveGray : AppColors.slate,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
