import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';

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
void showLanguageSelector(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.pureWhite : AppColors.ink;

  AppBottomSheet.show(
    context,
    title: 'settings.selectLanguage'.tr(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: supportedLanguages.map((lang) {
        final currentLang = ref.read(settingsProvider).language;
        final isSelected = currentLang == lang.code;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final locale = Locale(lang.code);
              await context.setLocale(locale);
              ref.read(settingsProvider.notifier).updateLanguage(lang.code);
              if (context.mounted) Navigator.pop(context);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentGreen.withOpacity(0.08)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lang.nativeName,
                      style: TextStyle(
                        color: isSelected ? AppColors.accentGreen : textColor,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accentGreen,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
