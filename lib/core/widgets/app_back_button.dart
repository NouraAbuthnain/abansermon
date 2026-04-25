import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Unified back button used across the entire app.
///
/// Visual design: Auth screens (44×44 circle, 20px icon, ink/white icon color,
/// soft 0.05 shadow). Interaction: Animated hover, press scale, pointer cursor,
/// Material ripple — from the app-level component.
class AppBackButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? icon;

  const AppBackButton({super.key, this.onPressed, this.icon});

  @override
  State<AppBackButton> createState() => _AppBackButtonState();
}

class _AppBackButtonState extends State<AppBackButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Background colors ────────────────────────────────────────────────
    final baseColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final hoverColor = isDark ? AppColors.secondaryDarkHover : AppColors.cloud;
    final pressedColor = isDark ? AppColors.secondaryDarkPressed : AppColors.secondaryLightPressed;
    final backgroundColor = _isPressed
        ? pressedColor
        : (_isHovered ? hoverColor : baseColor);

    // ── Icon color (auth style: ink in light, white in dark) ─────────────
    final contentColor = isDark ? Colors.white : AppColors.ink;

    // ── Dynamic shadow (auth style base: blur 10, offset 4, opacity 0.05) ─
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

    return Center(
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: dynamicShadows,
          ),
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.hardEdge,
            shape: const CircleBorder(),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onHover: (v) => setState(() => _isHovered = v),
              onHighlightChanged: (v) => setState(() => _isPressed = v),
              onTap: widget.onPressed ?? () => Navigator.maybePop(context),
              child: Center(
                child: widget.icon ??
                    Image.asset(
                      'assets/icons/left.png',
                      width: 20,
                      height: 20,
                      color: contentColor,
                      matchTextDirection: true,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
