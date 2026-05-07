import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/location_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/action_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_language_button.dart';
import '../data/mosque_repository.dart';
import '../domain/mosque.dart';
import 'widgets/recording_terms_sheet.dart';

class MosqueDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const MosqueDetailScreen({super.key, required this.id});

  @override
  ConsumerState<MosqueDetailScreen> createState() =>
      _MosqueDetailScreenState();
}

class _MosqueDetailScreenState extends ConsumerState<MosqueDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncMosques = ref.watch(mosqueRepositoryProvider);
    final userPos = ref.watch(userLocationProvider).valueOrNull;

    Mosque? mosque;
    for (final m in asyncMosques.valueOrNull ?? []) {
      if (m.id == widget.id) {
        mosque = m;
        break;
      }
    }

    if (mosque != null && userPos != null) {
      final meters = Geolocator.distanceBetween(
          userPos.latitude, userPos.longitude, mosque.lat, mosque.lng);
      final label = meters < 1000
          ? '${meters.round()} m'
          : '${(meters / 1000).toStringAsFixed(1)} km';
      mosque = mosque.copyWith(distance: label);
    }

    if (asyncMosques.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (mosque == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBackButton(),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'discovery.emptyResults'.tr(),
                    style: const TextStyle(color: AppColors.slate),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final m = mosque;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(mosque: m),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoPanel(mosque: m),
                    const SizedBox(height: 32),
                    Text(
                      'home.stats.archived'.tr().toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _ArchivePanel(mosque: m),
                  ],
                ),
              ),
              if (m.isLive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: AppButton(
                    label: 'discovery.joinLive'.tr(),
                    onPressed: () => context.push('/live/mock_session_${m.id}'),
                    variant: AppButtonVariant.primary,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: AppButton(
                    label: 'discovery.recordSermon'.tr(),
                    icon: Icons.mic_rounded,
                    onPressed: () => ActionGuard.execute(
                      context: context,
                      ref: ref,
                      onVolunteerAccess: () => RecordingTermsSheet.show(
                        context,
                        mosque: m,
                      ),
                    ),
                    variant: AppButtonVariant.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _Header extends ConsumerWidget {
  final Mosque mosque;

  const _Header({required this.mosque});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageNum = (mosque.id.hashCode % 5) + 1;
    final imagePath = 'assets/images/mosquephotos/mosquephoto$imageNum.jpg';

    return Stack(
      children: [
        // Large rounded mosque image
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),

        // Gradient overlay
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),

        // Back button + Language/Archive Row
        Positioned(
          top: 12,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppBackButton(),
              Row(
                children: [
                  const AppLanguageButton(),
                  const SizedBox(width: 12),
                  AppIconButton(
                    iconPath: 'assets/icons/cabinet.png',
                    onPressed: () {
                      AppBottomSheet.show(
                        context,
                        title: 'home.stats.archived'.tr(),
                        child: _ArchivePanel(mosque: mosque),
                      );
                    },
                    size: 44,
                    iconSize: 20,
                    hasShadow: true,
                    tooltip: 'home.stats.archived'.tr(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mosque Info Overlay
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      mosque.getName(context.locale.languageCode),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(isLive: mosque.isLive),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Image.asset('assets/icons/location.png', width: 14, height: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mosque.getAddress(context.locale.languageCode),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mosque.distance,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}






class _InfoPanel extends StatelessWidget {
  final Mosque mosque;

  const _InfoPanel({required this.mosque});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mosque.topic != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: AppColors.primaryTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.topicLabel'.tr(args: ['']),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        mosque.topic!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryTeal,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'profile.sections.about'.tr().toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          mosque.getAbout(context.locale.languageCode).isNotEmpty 
              ? mosque.getAbout(context.locale.languageCode)
              : '${mosque.getName(context.locale.languageCode)} — ${mosque.getAddress(context.locale.languageCode)}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
        const SizedBox(height: 16),
        if (mosque.imamName != null)
          _InfoRow(icon: Icons.person_outline, label: mosque.imamName!),
        _InfoRow(
          icon: Icons.my_location,
          label: '${mosque.lat.toStringAsFixed(4)}, ${mosque.lng.toStringAsFixed(4)}',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.slate),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivePanel extends ConsumerWidget {
  final Mosque mosque;

  const _ArchivePanel({required this.mosque});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.read(mosqueRepositoryProvider.notifier).getArchives(mosque.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<ArchivedKhutbah>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Center(child: Text('discovery.errorLoadingArchives'.tr(), style: const TextStyle(color: AppColors.error)));
        }
        final archives = snapshot.data ?? [];
        if (archives.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1E20) : AppColors.cloud.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open_rounded, size: 48, color: AppColors.slate.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'discovery.noArchivedKhutbahs'.tr(),
                    style: const TextStyle(color: AppColors.slate),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: archives.map((a) {
            final dateStr = DateFormat.yMMMd().format(a.date);
            final durationStr = a.durationSeconds != null && a.durationSeconds! > 0
                ? '${a.durationSeconds! ~/ 60} min'
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1E20) : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? [] : AppStyles.cardShadow,
                border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/khutbah-detail', extra: a),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            a.audioUrl != null && a.audioUrl!.isNotEmpty
                                ? Icons.play_arrow_rounded
                                : Icons.description_outlined,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.pureWhite : AppColors.ink,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate),
                                  ),
                                  if (durationStr != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(color: AppColors.slate, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      durationStr,
                                      style: const TextStyle(fontSize: 12, color: AppColors.slate),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final bool isLive;

  const _StatusBadge({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLive ? AppColors.accentGreen : AppColors.doveGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Image.asset('assets/icons/live.png', width: 12, height: 12, color: AppColors.pureWhite),
            const SizedBox(width: 4),
          ],
          Text(
            isLive
                ? 'discovery.filters.live'.tr()
                : 'discovery.filters.offline'.tr(),
            style: TextStyle(
              color: isLive ? AppColors.pureWhite : AppColors.slate,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
