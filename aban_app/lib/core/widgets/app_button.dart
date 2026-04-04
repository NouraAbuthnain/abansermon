import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  Variant enum
// ─────────────────────────────────────────────

enum AppButtonVariant { primary, secondary, tertiary }

// ─────────────────────────────────────────────
//  AppButton — unified button component
// ─────────────────────────────────────────────

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isFullWidth = true,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isFullWidth;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    Widget button = switch (variant) {
      AppButtonVariant.primary => _PrimaryButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
      AppButtonVariant.secondary => _SecondaryButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
      AppButtonVariant.tertiary => _TertiaryButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
    };

    if (isFullWidth && variant != AppButtonVariant.tertiary) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

// ─────────────────────────────────────────────
//  Shared constants
// ─────────────────────────────────────────────

const _kHeight = 48.0;
const _kRadius = BorderRadius.all(Radius.circular(14));
const _kPaddingH = EdgeInsets.symmetric(horizontal: 20, vertical: 0);
const _kLoadingSize = 20.0;
const _kLoadingStroke = 2.5;

// ─────────────────────────────────────────────
//  Primary Button  (teal bg, white text)
// ─────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: _kHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          // Background
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark
                  ? AppColors.primaryTeal.withValues(alpha: 0.3)
                  : AppColors.primaryTeal.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryTealDark;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryTeal.withValues(alpha: 0.88);
            }
            return AppColors.primaryTeal;
          }),
          // Foreground (text + icon)
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.pureWhite.withValues(alpha: 0.45);
            }
            return AppColors.pureWhite;
          }),
          // Elevation / shadow
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 0;
            if (states.contains(WidgetState.hovered)) return 4;
            return 2;
          }),
          shadowColor: WidgetStateProperty.all(
            AppColors.primaryTeal.withValues(alpha: 0.40),
          ),
          // Focus ring
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return AppColors.pureWhite.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.pureWhite.withValues(alpha: 0.08);
            }
            return null;
          }),
          // Shape
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: _kRadius),
          ),
          padding: WidgetStateProperty.all(_kPaddingH),
          // Focus border
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(
                color: AppColors.primaryTeal.withValues(alpha: 0.5),
                width: 2,
              );
            }
            return BorderSide.none;
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
        child: _ButtonContent(
          label: label,
          isLoading: isLoading,
          loadingColor: AppColors.pureWhite,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Secondary Button  (greenMist bg, teal text)
// ─────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.primaryTeal.withValues(alpha: 0.18) : AppColors.greenMist;
    final fgColor = isDark ? AppColors.accentGreen : AppColors.primaryTeal;

    return SizedBox(
      height: _kHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return bgColor.withValues(alpha: 0.45);
            }
            if (states.contains(WidgetState.pressed)) {
              return isDark
                  ? AppColors.primaryTeal.withValues(alpha: 0.28)
                  : AppColors.greenMist.withValues(alpha: 0.7);
            }
            if (states.contains(WidgetState.hovered)) {
              return bgColor.withValues(alpha: 0.80);
            }
            return bgColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return fgColor.withValues(alpha: 0.4);
            }
            return fgColor;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 0;
            if (states.contains(WidgetState.hovered)) return 2;
            return 0;
          }),
          shadowColor: WidgetStateProperty.all(
            AppColors.primaryTeal.withValues(alpha: 0.15),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)) {
              return fgColor.withValues(alpha: 0.08);
            }
            return null;
          }),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: _kRadius),
          ),
          padding: WidgetStateProperty.all(_kPaddingH),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: fgColor.withValues(alpha: 0.5), width: 2);
            }
            return BorderSide.none;
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
        child: _ButtonContent(
          label: label,
          isLoading: isLoading,
          loadingColor: fgColor,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Tertiary Button  (text only, accent green)
// ─────────────────────────────────────────────

class _TertiaryButton extends StatelessWidget {
  const _TertiaryButton({
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.accentGreen : AppColors.accentGreen;

    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return color.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.pressed)) {
            return color.withValues(alpha: 0.75);
          }
          return color;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return color.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return color.withValues(alpha: 0.10);
          }
          return null;
        }),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        minimumSize: WidgetStateProperty.all(const Size(0, 36)),
        animationDuration: const Duration(milliseconds: 150),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: false,
        loadingColor: color,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Internal: button content (label + icons + loader)
// ─────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.loadingColor,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final bool isLoading;
  final Color loadingColor;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: _kLoadingSize,
        height: _kLoadingSize,
        child: CircularProgressIndicator(
          strokeWidth: _kLoadingStroke,
          valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
        ),
      );
    }

    if (leadingIcon == null && trailingIcon == null) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 8)],
        Text(label),
        if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon!],
      ],
    );
  }
}
