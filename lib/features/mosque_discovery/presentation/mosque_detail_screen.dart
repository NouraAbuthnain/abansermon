import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/location_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/action_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
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
  int _selectedTabIndex = 0;

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
              _Header(mosque: mosque),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ActionRow(mosque: mosque),
                    const SizedBox(height: 20),
                    _TabBar(
                      selected: _selectedTabIndex,
                      onChanged: (i) =>
                          setState(() => _selectedTabIndex = i),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedTabIndex == 0)
                      ..._buildTranscript(mosque)
                    else if (_selectedTabIndex == 1)
                      ..._buildTranslation(mosque)
                    else
                      _InfoPanel(mosque: mosque),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTranscript(Mosque mosque) {
    if (mosque.transcript.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'discovery.emptyResults'.tr(),
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
        ),
      ];
    }
    return [
      for (int i = 0; i < mosque.transcript.length; i++)
        _TranscriptCard(
          text: mosque.transcript[i].ar,
          label: mosque.transcript[i].time,
          isArabic: true,
        ),
    ];
  }

  List<Widget> _buildTranslation(Mosque mosque) {
    if (mosque.transcript.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'discovery.emptyResults'.tr(),
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
        ),
      ];
    }
    return [
      for (int i = 0; i < mosque.transcript.length; i++)
        _TranscriptCard(
          text: mosque.transcript[i].en,
          label: mosque.transcript[i].time,
          isArabic: false,
        ),
    ];
  }
}

class _Header extends ConsumerWidget {
  final Mosque mosque;

  const _Header({required this.mosque});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Mosque'),
        content: Text(
          'Remove "${mosque.name}" from the list? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(mosqueRepositoryProvider.notifier).deleteMosque(mosque.id);
    if (context.mounted) context.go('/mosques');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppBackButton(),
              Tooltip(
                message: 'Remove mosque',
                child: InkWell(
                  onTap: () => _confirmDelete(context, ref),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  mosque.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.pureWhite,
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
              const Icon(Icons.location_on,
                  size: 14, color: AppColors.doveGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mosque.address,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.doveGray),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mosque.distance,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.doveGray,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (mosque.imamName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.doveGray),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    mosque.imamName!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.doveGray),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (mosque.topic != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_outlined,
                      size: 14, color: AppColors.accentGreen),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      mosque.topic!,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.pureWhite),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  final Mosque mosque;

  const _ActionRow({required this.mosque});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mosque.isLive) {
      return AppButton(
        label: 'discovery.joinLive'.tr(),
        onPressed: () => context.push('/live/mock_session_${mosque.id}'),
        variant: AppButtonVariant.primary,
      );
    }
    return AppButton(
      label: 'discovery.recordSermon'.tr(),
      icon: Icons.mic,
      onPressed: () {
        ActionGuard.execute(
          context: context,
          ref: ref,
          onVolunteerAccess: () =>
              RecordingTermsSheet.show(context, mosque: mosque),
        );
      },
      variant: AppButtonVariant.primary,
    );
  }
}

class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppStyles.cardShadow,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab(0, 'Arabic'),
          _tab(1, 'English'),
          _tab(2, 'Info'),
        ],
      ),
    );
  }

  Widget _tab(int index, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected == index ? AppColors.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected == index
                  ? AppColors.pureWhite
                  : AppColors.slate,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            mosque.about ?? '${mosque.name} — ${mosque.address}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (mosque.imamName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppColors.slate),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    mosque.imamName!,
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.my_location,
                  size: 16, color: AppColors.slate),
              const SizedBox(width: 6),
              Text(
                '${mosque.lat.toStringAsFixed(4)}, ${mosque.lng.toStringAsFixed(4)}',
                style: const TextStyle(
                    color: AppColors.slate, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
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
            const Icon(Icons.wifi_tethering,
                size: 10, color: AppColors.pureWhite),
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
