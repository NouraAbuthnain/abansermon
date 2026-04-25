import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final List<String> _textSizeLabels = ['settings.textSizeSmall', 'settings.textSizeMedium', 'settings.textSizeLarge'];

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'ar': return 'العربية';
      case 'ur': return 'اردو';
      case 'bn': return 'বাংলা';
      default: return 'English';
    }
  }

  int _getTextSizeIndex(double scale) {
    if (scale <= 0.85) return 0;
    if (scale >= 1.15) return 2;
    return 1;
  }

  double _getScaleFromIndex(int index) {
    if (index == 0) return 0.85;
    if (index == 2) return 1.15;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final settingsCache = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;
    final dividerColor = isDark
        ? AppColors.pureWhite.withOpacity(0.06)
        : AppColors.doveGray.withOpacity(0.25);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'settings.title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick Settings ──
            _buildSectionLabel('settings.quickSettings'.tr(), subtitleColor),
            const SizedBox(height: 8),
            _buildCard(
              cardColor: cardColor,
              isDark: isDark,
              children: [
                _buildToggleRow(
                  context,
                  icon: 'assets/icons/theme.png',
                  label: 'settings.darkMode'.tr(),
                  value: settingsCache.themeMode == ThemeMode.dark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateThemeMode(val ? ThemeMode.dark : ThemeMode.light),
                ),
                _buildDivider(dividerColor),
                _buildToggleRow(
                  context,
                  icon: 'assets/icons/notification.png',
                  label: 'settings.notifications'.tr(),
                  value: settingsCache.notifications,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateNotifications(val),
                ),
                _buildDivider(dividerColor),
                _buildToggleRow(
                  context,
                  icon: null,
                  iconData: Icons.headset_rounded,
                  label: 'settings.audioFirst'.tr(),
                  subtitle: 'settings.audioFirstSubtitle'.tr(),
                  value: settingsCache.audioFirst,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateAudioFirst(val),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Preferences ──
            _buildSectionLabel('settings.preferences'.tr(), subtitleColor),
            const SizedBox(height: 8),
            _buildCard(
              cardColor: cardColor,
              isDark: isDark,
              children: [
                _buildTextSizeStepper(
                  context,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                ),
                _buildDivider(dividerColor),
                _buildLanguageRow(
                  context,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── App Info Footer ──
            Center(
              child: Column(
                children: [
                  Text(
                    'settings.version'.tr(args: ['1.0.0-beta']),
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'settings.designedBy'.tr(),
                    style: TextStyle(
                      color: subtitleColor.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section Label
  // ─────────────────────────────────────────────
  Widget _buildSectionLabel(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section Card Container
  // ─────────────────────────────────────────────
  Widget _buildCard({
    required Color cardColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppStyles.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  // ─────────────────────────────────────────────
  // Toggle Row (Dark Mode, Notifications, Audio First)
  // ─────────────────────────────────────────────
  Widget _buildToggleRow(
    BuildContext context, {
    required String? icon,
    IconData? iconData,
    required String label,
    String? subtitle,
    required bool value,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: subtitle != null ? 60 : 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Icon
            if (icon != null)
              Image.asset(
                icon,
                width: 20,
                height: 20,
                color: isDark ? AppColors.doveGray : AppColors.slate,
              )
            else if (iconData != null)
              Icon(
                iconData,
                size: 20,
                color: isDark ? AppColors.doveGray : AppColors.slate,
              ),
            const SizedBox(width: 14),

            // Label + optional subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Toggle Switch
            SizedBox(
              height: 28,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.pureWhite,
                  activeTrackColor: AppColors.accentGreen,
                  inactiveThumbColor: AppColors.pureWhite,
                  inactiveTrackColor: isDark
                      ? AppColors.pureWhite.withOpacity(0.12)
                      : AppColors.doveGray,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Text Size Stepper Row
  // ─────────────────────────────────────────────
  Widget _buildTextSizeStepper(
    BuildContext context, {
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.text_fields_rounded,
              size: 20,
              color: isDark ? AppColors.doveGray : AppColors.slate,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'settings.textSize'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Stepper: Small / Medium / Large
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.pureWhite.withOpacity(0.06)
                    : AppColors.cloud,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final settingsCache = ref.watch(settingsProvider);
                  final isSelected = _getTextSizeIndex(settingsCache.textScaleFactor) == index;
                  return GestureDetector(
                    onTap: () => ref.read(settingsProvider.notifier).updateTextScaleFactor(_getScaleFromIndex(index)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _textSizeLabels[index].tr(),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.pureWhite
                              : subtitleColor,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Language Row
  // ─────────────────────────────────────────────
  Widget _buildLanguageRow(
    BuildContext context, {
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguagePicker(context, isDark),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/translate.png',
                  width: 20,
                  height: 20,
                  color: isDark ? AppColors.doveGray : AppColors.slate,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'settings.language'.tr(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _getLanguageName(ref.watch(settingsProvider).language),
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: subtitleColor.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Language Picker Bottom Sheet
  // ─────────────────────────────────────────────
  void _showLanguagePicker(BuildContext context, bool isDark) {
    final sheetBg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                Text(
                  'settings.selectLanguage'.tr(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...context.supportedLocales.map((locale) {
                  final isSelected = ref.watch(settingsProvider).language == locale.languageCode;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await context.setLocale(locale);
                        ref.read(settingsProvider.notifier).updateLanguage(locale.languageCode);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentGreen.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getLanguageName(locale.languageCode),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.accentGreen
                                      : textColor,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                color: AppColors.accentGreen,
                                size: 20,
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

  // ─────────────────────────────────────────────
  // Divider
  // ─────────────────────────────────────────────
  Widget _buildDivider(Color dividerColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 50, right: 16),
      child: Divider(height: 1, color: dividerColor),
    );
  }
}
