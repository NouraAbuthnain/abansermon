import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                        'Nearby Mosques',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                      AppButton(
                        label: 'View Map',
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
                      _buildStatCard('3', 'LIVE NOW', 'mosques'),
                      const SizedBox(width: 12),
                      _buildStatCard('128', 'ARCHIVED', 'khutbahs'),
                      const SizedBox(width: 12),
                      _buildStatCard('12', 'LANGUAGES', 'available'),
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
        left: 20,
        right: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assalamu Alaikum',
                style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Welcome to ABAN',
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildGlassIconButton(Icons.person, () => context.push('/login')),
              const SizedBox(width: 12),
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
        child: Icon(icon, color: AppColors.pureWhite, size: 20),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppStyles.cardShadow,
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
