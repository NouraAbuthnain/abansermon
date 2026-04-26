import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class AddMosqueChooserSheet extends StatelessWidget {
  const AddMosqueChooserSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMosqueChooserSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + bottomInset),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.doveGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'discovery.addMosque.title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'discovery.addMosque.subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Icons.add_location_alt_outlined,
            title: 'discovery.addMosque.viaMap'.tr(),
            subtitle: 'discovery.addMosque.viaMapDesc'.tr(),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/add-mosque/map');
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.search,
            title: 'discovery.addMosque.viaSearch'.tr(),
            subtitle: 'discovery.addMosque.viaSearchDesc'.tr(),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/add-mosque/search');
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.doveGray),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.accentGreen),
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
              const Icon(Icons.chevron_right, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}
