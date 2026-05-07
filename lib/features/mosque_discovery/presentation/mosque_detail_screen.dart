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
                    const SizedBox(height: 24),
                    _TranscriptSection(mosque: m),
                    const SizedBox(height: 24),
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

class _TranscriptSection extends StatelessWidget {
  final Mosque mosque;

  const _TranscriptSection({required this.mosque});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final transcript = mosque.transcript;

    if (transcript.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Image.asset('assets/icons/translate.png', width: 18, height: 18, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(
                'home.stats.khutbahsLabel'.tr().toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primaryTeal,
                    ),
              ),
            ],
          ),
        ),
        for (final item in transcript)
          _TranscriptCard(
            text: isArabic ? item.ar : item.en,
            label: item.time,
            isArabic: isArabic,
          ),
      ],
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
                  _ArchiveIconButton(mosque: mosque),
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
                      mosque.name,
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
                      mosque.address,
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

class _ArchiveIconButton extends StatefulWidget {
  final Mosque mosque;

  const _ArchiveIconButton({required this.mosque});

  @override
  State<_ArchiveIconButton> createState() => _ArchiveIconButtonState();
}

class _ArchiveIconButtonState extends State<_ArchiveIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final hoverColor = isDark ? AppColors.secondaryDarkHover : AppColors.cloud;
    final pressedColor = isDark ? AppColors.secondaryDarkPressed : AppColors.secondaryLightPressed;
    final backgroundColor = _isPressed
        ? pressedColor
        : (_isHovered ? hoverColor : baseColor);
    final contentColor = isDark ? Colors.white : AppColors.ink;

    final shadowColor = Colors.black.withValues(alpha: 0.05);
    final dynamicShadows = _isPressed
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: shadowColor,
              blurRadius: _isHovered ? 14 : 10,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ];

    return AnimatedScale(
      scale: _isPressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: dynamicShadows,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.hardEdge,
          shape: const CircleBorder(),
          child: InkWell(
            onHover: (v) => setState(() => _isHovered = v),
            onHighlightChanged: (v) => setState(() => _isPressed = v),
            onTap: () {
              AppBottomSheet.show(
                context,
                title: 'home.stats.archived'.tr(),
                child: _ArchivePanel(mosque: widget.mosque),
              );
            },
            child: Center(
              child: Image.asset(
                'assets/icons/cabinet.png',
                width: 20,
                height: 20,
                color: contentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class _TranscriptCard extends StatelessWidget {
  final String text;
  final String label;
  final bool isArabic;

  const _TranscriptCard({
    required this.text,
    required this.label,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection:
                isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: isArabic ? 'Cairo' : null,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.slate),
          ),
        ],
      ),
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
          'discovery.filters.all'.tr().toUpperCase(), // Or add an 'About' key if exists
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          mosque.about ?? '${mosque.name} — ${mosque.address}.',
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
          return const Center(child: Text('Error loading archives', style: TextStyle(color: AppColors.error)));
        }
        final archives = snapshot.data ?? [];
        if (archives.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No archived khutbahs yet.',
                style: TextStyle(color: AppColors.slate),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: archives.map((a) {
              final dateStr = DateFormat.yMMMd().format(a.date);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: AppColors.accentGreen),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: AppColors.slate),
                              const SizedBox(width: 4),
                              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
