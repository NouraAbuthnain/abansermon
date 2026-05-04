import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../features/mosque_discovery/domain/mosque.dart';
import '../../theme/app_theme.dart';

class MosqueCardWidget extends StatelessWidget {
  final String name;
  final String address;
  final MosqueStatus status;
  final String distance;
  final VoidCallback onTap;

  const MosqueCardWidget({
    super.key,
    required this.name,
    required this.address,
    required this.status,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (status) {
      case MosqueStatus.active:
        statusBgColor = AppColors.accentGreen;
        statusTextColor = AppColors.pureWhite;
        statusLabel = 'home.mosqueStatus.live'.tr();
        break;
      case MosqueStatus.inactive:
        statusBgColor = AppColors.doveGray;
        statusTextColor = AppColors.slate;
        statusLabel = 'home.mosqueStatus.offline'.tr();
        break;
      case MosqueStatus.pending:
        statusBgColor = AppColors.warning;
        statusTextColor = AppColors.ink;
        statusLabel = 'home.mosqueStatus.pending'.tr();
        break;
    }

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
                              name,
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
                                if (status == MosqueStatus.active) ...[
                                  const Icon(Icons.wifi_tethering,
                                      size: 10, color: AppColors.pureWhite),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
                          const Icon(Icons.location_on,
                              size: 14, color: AppColors.slate),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
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
                  distance,
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
