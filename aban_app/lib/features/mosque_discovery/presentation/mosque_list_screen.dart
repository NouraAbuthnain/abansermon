import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/presentation/widgets/live_khutbah_card.dart';
import '../../../core/presentation/widgets/mosque_card.dart';

class MosqueListScreen extends StatelessWidget {
  const MosqueListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (Gradient Hero)
            _buildHeroHeader(context),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Khutbah hero card
                  GestureDetector(
                    onTap: () => context.push('/live/mock_session_1'),
                    child: const LiveKhutbahCard(),
                  ),
                  const SizedBox(height: 32),

                  // Featured Mosques Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'home.nearbyMosques'.tr(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      AppButton(
                        label: 'home.viewMap'.tr(),
                        onPressed: () => context.push('/map'),
                        variant: AppButtonVariant.tertiary,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mosques List
                  MosqueCardWidget(
                    name: 'Al-Noor Mosque',
                    address: '123 Main St, Downtown',
                    status: MosqueStatus.active,
                    distance: '0.5 km',
                    onTap: () => context.push('/live/mock_session_al_noor'),
                  ),
                  MosqueCardWidget(
                    name: 'Masjid Al-Iman',
                    address: '456 Oak Ave, Midtown',
                    status: MosqueStatus.active,
                    distance: '1.2 km',
                    onTap: () => context.push('/live/mock_session_al_iman'),
                  ),
                  MosqueCardWidget(
                    name: 'Islamic Center',
                    address: '789 Cedar Rd, Uptown',
                    status: MosqueStatus.inactive,
                    distance: '2.8 km',
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),

                  // Quick Stats
                  Row(
                    children: [
                      _buildStatCard(context, '3', 'home.stats.liveNow'.tr(), 'home.stats.mosquesLabel'.tr()),
                      const SizedBox(width: 8),
                      _buildStatCard(context, '128', 'home.stats.archived'.tr(), 'home.stats.khutbahsLabel'.tr()),
                      const SizedBox(width: 8),
                      _buildStatCard(context, '12', 'home.stats.languages'.tr(), 'home.stats.availableLabel'.tr()),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 32,
        left: 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.welcome'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.pureWhite.withOpacity(0.7)),
              ),
              const SizedBox(height: 8),
              Text(
                'home.subtitle'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.pureWhite,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildGlassIconButton(Icons.person, () => context.push('/login')),
              const SizedBox(width: 16),
              _buildGlassIconButton(
                  Icons.settings, () => context.push('/settings')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.pureWhite, size: 24),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppStyles.cardShadow,
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accentGreen,
                    )),
            const SizedBox(height: 8),
            Text(
              sub,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
