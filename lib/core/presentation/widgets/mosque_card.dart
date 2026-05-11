import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../features/mosque_discovery/domain/mosque.dart';
import '../../theme/app_theme.dart';

class MosqueCardWidget extends StatelessWidget {
  final Mosque mosque;
  final VoidCallback onTap;

  const MosqueCardWidget({
    super.key,
    required this.mosque,
    required this.onTap,
  });
  

  @override
  Widget build(BuildContext context) {
    final bool isLive = mosque.isLive;
    final Color statusBgColor = isLive ? AppColors.accentGreen : AppColors.doveGray;
    final Color statusTextColor = isLive ? AppColors.pureWhite : AppColors.slate;
    final String statusLabel = isLive 
        ? 'home.mosqueStatus.live'.tr() 
        : 'home.mosqueStatus.offline'.tr();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                        Expanded(
                            child: Text(
                              mosque.getLocalizedName(),
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLive) ...[
                                  Image.asset(
                                    'assets/icons/live.png',
                                    width: 12,
                                    height: 12,
                                    color: AppColors.pureWhite,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    // Use English for status label in Arabic if requested?
                                    // No, requirement says all text in selected language.
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/location.png',
                            width: 14,
                            height: 14,
                            color: isDark ? AppColors.doveGray : AppColors.slate,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              mosque.getLocalizedAddress(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.slate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  mosque.distance,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
