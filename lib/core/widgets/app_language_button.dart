import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'language_selector.dart';

/// Reusable language switch button (globe icon + lang code).
///
/// Shows the unified [showLanguageSelector] bottom sheet when tapped.
/// Use in onboarding, login, sign-up, OTP headers.
class AppLanguageButton extends ConsumerStatefulWidget {
  const AppLanguageButton({super.key});

  @override
  ConsumerState<AppLanguageButton> createState() => _AppLanguageButtonState();
}

class _AppLanguageButtonState extends ConsumerState<AppLanguageButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentLang = context.locale.languageCode.toUpperCase();

    // ── Background colors ─────────────────────────────────────────────
    final baseColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final hoverColor = isDark ? AppColors.secondaryDarkHover : AppColors.cloud;
    final pressedColor = isDark ? AppColors.secondaryDarkPressed : AppColors.secondaryLightPressed;
    final backgroundColor = _isPressed
        ? pressedColor
        : (_isHovered ? hoverColor : baseColor);

    // ── Content color ─────────────────────────────────────────────────
    final contentColor = isDark ? Colors.white : AppColors.ink;

    // ── Dynamic shadow ────────────────────────────────────────────────
    final shadowColor = Colors.black.withOpacity(0.05);
    final dynamicShadows = _isPressed
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: shadowColor,
              blurRadius: _isHovered ? 14 : 10,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ];

    return AnimatedScale(
      scale: _isPressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: dynamicShadows,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onHover: (v) => setState(() => _isHovered = v),
            onHighlightChanged: (v) => setState(() => _isPressed = v),
            onTap: () => showLanguageSelector(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/translate.png',
                    width: 20,
                    height: 20,
                    color: contentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentLang,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: contentColor,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
