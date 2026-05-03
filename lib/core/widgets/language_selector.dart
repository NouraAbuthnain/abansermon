import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// The app's supported languages in display order.
class AppLanguage {
  final String code;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.nativeName,
  });
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(code: 'en', nativeName: 'English'),
  AppLanguage(code: 'ar', nativeName: 'العربية'),
  AppLanguage(code: 'ur', nativeName: 'اردو'),
  AppLanguage(code: 'bn', nativeName: 'বাংলা'),
];

/// Returns the native language name for a given language code.
String getLanguageName(String code) {
  for (final lang in supportedLanguages) {
    if (lang.code == code) return lang.nativeName;
  }
  return 'English';
}

/// Shows the unified language selector bottom sheet.
///
/// Call this from anywhere: onboarding, settings, login, signup, OTP, profile.
/// It uses the same design, spacing, colors, and checkmark everywhere.
void showLanguageSelector(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final sheetBg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
  final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
  final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: sheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final currentLang = ref.read(settingsProvider).language;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ──
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subtitleColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              Text(
                'settings.selectLanguage'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // ── Language List ──
              ...supportedLanguages.map((lang) {
                final isSelected = currentLang == lang.code;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final locale = Locale(lang.code);
                      await ctx.setLocale(locale);
                      ref.read(settingsProvider.notifier).updateLanguage(lang.code);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGreen.withOpacity(0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Language name
                          Expanded(
                            child: Text(
                              lang.nativeName,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.accentGreen
                                    : textColor,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),

                          // Checkmark
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.accentGreen,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
