import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

class AddMosqueChooserSheet extends StatelessWidget {
  const AddMosqueChooserSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: 'discovery.addMosque.title'.tr(),
      child: const AddMosqueChooserSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'discovery.addMosque.subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            iconPath: 'assets/icons/location.png',
            title: 'discovery.addMosque.viaMap'.tr(),
            subtitle: 'discovery.addMosque.viaMapDesc'.tr(),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/add-mosque/map');
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            iconPath: 'assets/icons/search.png',
            title: 'discovery.addMosque.viaSearch'.tr(),
            subtitle: 'discovery.addMosque.viaSearchDesc'.tr(),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/add-mosque/search');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.pureWhite.withOpacity(0.1) : AppColors.doveGray.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.slate.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
