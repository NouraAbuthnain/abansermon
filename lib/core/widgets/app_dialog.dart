import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

enum AppDialogType {
  success,
  error,
  warning,
  info,
  confirmation,
}

class AppDialog extends StatelessWidget {
  final AppDialogType type;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool isDestructive;

  const AppDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.isDestructive = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required AppDialogType type,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimaryPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: false,
      builder: (context) => AppDialog(
        type: type,
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        onPrimaryPressed: onPrimaryPressed,
        secondaryLabel: secondaryLabel,
        onSecondaryPressed: onSecondaryPressed,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      backgroundColor: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                height: 1.2,
                color: isDark ? AppColors.pureWhite : AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.doveGray : AppColors.slate,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    Color color;
    String iconPath;

    switch (type) {
      case AppDialogType.success:
        color = AppColors.accentGreen;
        iconPath = 'assets/icons/accept.png';
        break;
      case AppDialogType.error:
        color = AppColors.error;
        iconPath = 'assets/icons/cancel.png';
        break;
      case AppDialogType.warning:
        color = const Color(0xFFFFB300); // Amber/Warning
        iconPath = 'assets/icons/warning.png';
        break;
      case AppDialogType.info:
      case AppDialogType.confirmation:
        color = AppColors.primaryTeal;
        iconPath = 'assets/icons/information.png';
        break;
    }

    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          iconPath,
          width: 40,
          height: 40,
          color: color,
          errorBuilder: (context, error, stackTrace) => Icon(
            _getFallbackIcon(),
            color: color,
            size: 40,
          ),
        ),
      ),
    );
  }

  IconData _getFallbackIcon() {
    switch (type) {
      case AppDialogType.success:
        return Icons.check_circle_rounded;
      case AppDialogType.error:
        return Icons.error_rounded;
      case AppDialogType.warning:
        return Icons.warning_rounded;
      case AppDialogType.info:
      case AppDialogType.confirmation:
        return Icons.info_rounded;
    }
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: primaryLabel,
          onPressed: onPrimaryPressed,
          variant: isDestructive ? AppButtonVariant.error : AppButtonVariant.primary,
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 12),
          AppButton(
            label: secondaryLabel!,
            onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
            variant: AppButtonVariant.tertiary,
          ),
        ],
      ],
    );
  }
}
