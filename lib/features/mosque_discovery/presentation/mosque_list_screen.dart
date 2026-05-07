import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/mosque_card.dart';
import '../../../core/presentation/widgets/scaffold_with_nav.dart';
import '../data/mosque_repository.dart';
import '../domain/mosque.dart';
import 'widgets/prayer_times_card.dart';

class MosqueListScreen extends ConsumerWidget {
  const MosqueListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mosques = ref.watch(filteredMosquesProvider);
    final liveCount = ref.watch(liveMosqueCountProvider);
    final totalMosques = mosques.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: NavBarHeight.of(context) + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prayer Times Card
            const PrayerTimesCard(),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Section
                  _buildSectionLabel('home.stats.title'.tr().toUpperCase(), subtitleColor),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStatCard(context, liveCount.toString(), 'home.stats.liveNow'.tr(), cardColor, isDark),
                        const SizedBox(width: 8),
                        _buildStatCard(context, totalMosques.toString(), 'home.stats.mosquesLabel'.tr(), cardColor, isDark),
                        const SizedBox(width: 8),
                        _buildStatCard(context, '4', 'home.stats.languages'.tr(), cardColor, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nearby Mosques Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('home.nearbyMosques'.tr().toUpperCase(), subtitleColor),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/mosques'),
                            child: Text(
                              'home.viewAll'.tr(),
                              style: const TextStyle(
                                color: AppColors.accentGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => context.push('/map'),
                            child: Text(
                              'home.viewMap'.tr(),
                              style: const TextStyle(
                                color: AppColors.accentGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (mosques.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'home.emptyResults'.tr(),
                          style: TextStyle(color: subtitleColor),
                        ),
                      ),
                    )
                  else
                    ...mosques.take(3).toList().asMap().entries.map((entry) => _HomeMosqueCard(
                          mosque: entry.value,
                          index: entry.key,
                          onTap: () => context.push('/mosque/${entry.value.id}'),
                        )),
                  const SizedBox(height: 32),

                  // Quick Access Section
                  _buildSectionLabel('settings.quickSettings'.tr(), subtitleColor),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildQuickAccessItem(
                          context,
                          'services.quran.title'.tr(),
                          'assets/icons/quran.png',
                          () => context.push('/quran'),
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickAccessItem(
                          context,
                          'services.liveTranslation.title'.tr(),
                          'assets/icons/translate.png',
                          () => context.go('/mosques'),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Color cardColor, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : AppStyles.cardShadow,
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.doveGray : AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context,
    String title,
    String iconPath,
    VoidCallback onTap,
    bool isDark,
  ) {
    final cardColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110, // Adjusted for better rhythm with other cards
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20), // Harmonized with rest of UI
            boxShadow: isDark ? [] : AppStyles.cardShadow, // Sync with StatCard
            border: Border.all(
              color: isDark 
                  ? AppColors.pureWhite.withValues(alpha: 0.05) 
                  : AppColors.primaryTeal.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: 28, // Slightly more balanced size
                height: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isDark ? AppColors.pureWhite : AppColors.ink,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMosqueCard extends StatelessWidget {
  final Mosque mosque;
  final int index;
  final VoidCallback onTap;

  const _HomeMosqueCard({
    required this.mosque,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final langCode = context.locale.languageCode;
    
    // Ensure different images for the home page items by combining ID hash and list index
    final imageNum = ((mosque.id.hashCode + index) % 5) + 1;
    final imagePath = 'assets/images/mosquephotos/mosquephoto$imageNum.jpg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : AppStyles.cardShadow,
          border: Border.all(
            color: isDark 
                ? AppColors.pureWhite.withValues(alpha: 0.05) 
                : AppColors.primaryTeal.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imagePath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.greenMist,
                  child: const Icon(Icons.mosque, color: AppColors.primaryTeal),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mosque.getName(langCode),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (mosque.isLive)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.accentGreen),
                              const SizedBox(width: 4),
                              Text(
                                'home.mosqueStatus.live'.tr().toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accentGreen,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.slate),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mosque.getAddress(langCode),
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mosque.isLive ? 'home.mosqueStatus.live'.tr() : 'home.mosqueStatus.offline'.tr(),
                    style: TextStyle(
                      color: mosque.isLive ? AppColors.accentGreen : AppColors.slate,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Text(
              mosque.distance,
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

