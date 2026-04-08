import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;

  const AppBackButton({super.key, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.hardEdge,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed ?? () => Navigator.maybePop(context),
            child: Center(
              child: icon ?? Image.asset(
                'assets/icons/left.png',
                width: 24,
                height: 24,
                color: AppColors.primaryTeal,
                matchTextDirection: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
