import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showCloseButton;
  final EdgeInsets? padding;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.showCloseButton = true,
    this.padding,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    bool showCloseButton = true,
    EdgeInsets? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        showCloseButton: showCloseButton,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pureWhite : AppColors.ink,
                    ),
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.doveGray : AppColors.slate,
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: padding ?? const EdgeInsets.all(24),
              child: child,
            ),
          ),
          
          // Bottom Safe Area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
