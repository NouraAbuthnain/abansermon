import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.iconPath,
    this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.hasShadow = false,
    this.matchTextDirection = false,
  });

  final String iconPath;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool hasShadow;
  final bool matchTextDirection;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? AppColors.pureWhite.withValues(alpha: 0.08)
        : AppColors.secondaryLightBg;

    final defaultIconColor = isDark ? AppColors.pureWhite : AppColors.primaryTeal;

    final bg = widget.backgroundColor ?? defaultBg;
    final fg = widget.iconColor ?? defaultIconColor;

    // Hover/Pressed colors
    final hoverColor = isDark
        ? AppColors.pureWhite.withValues(alpha: 0.12)
        : AppColors.secondaryLightHover;
    final pressedColor = isDark
        ? AppColors.pureWhite.withValues(alpha: 0.15)
        : AppColors.secondaryLightPressed;

    final backgroundColor = widget.onPressed == null
        ? bg.withValues(alpha: 0.04)
        : (_isPressed ? pressedColor : (_isHovered ? hoverColor : bg));

    final contentColor = widget.onPressed == null ? fg.withValues(alpha: 0.3) : fg;

    final dynamicShadows = (widget.hasShadow && widget.onPressed != null && !_isPressed)
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.05),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ]
        : <BoxShadow>[];

    return Tooltip(
      message: widget.tooltip ?? '',
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: dynamicShadows,
            border: _isFocused
                ? Border.all(
                    color: fg.withValues(alpha: 0.5),
                    width: 2,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              onHover: (v) => setState(() => _isHovered = v),
              onHighlightChanged: (v) => setState(() => _isPressed = v),
              onFocusChange: (v) => setState(() => _isFocused = v),
              child: Center(
                child: Image.asset(
                  widget.iconPath,
                  width: widget.iconSize,
                  height: widget.iconSize,
                  color: contentColor,
                  matchTextDirection: widget.matchTextDirection,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
