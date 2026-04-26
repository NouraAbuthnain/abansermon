import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/action_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../data/mosque_repository.dart';
import '../domain/mosque.dart';
import 'widgets/add_mosque_chooser_sheet.dart';
import 'widgets/recording_terms_sheet.dart';

class MosqueMapScreen extends ConsumerStatefulWidget {
  const MosqueMapScreen({super.key});

  @override
  ConsumerState<MosqueMapScreen> createState() => _MosqueMapScreenState();
}

class _MosqueMapScreenState extends ConsumerState<MosqueMapScreen> {
  // Default position: Riyadh, Saudi Arabia.
  static const LatLng _initialCenter = LatLng(24.7136, 46.6753);
  static const double _initialZoom = 11.5;

  final MapController _mapController = MapController();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(mosqueQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers(List<Mosque> mosques) {
    return [
      for (final m in mosques)
        Marker(
          point: LatLng(m.lat, m.lng),
          width: 44,
          height: 54,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _showMosqueSheet(m),
            child: _MapPin(isLive: m.isLive),
          ),
        ),
    ];
  }

  void _showMosqueSheet(Mosque mosque) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MosqueSheet(mosque: mosque),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(mosqueQueryProvider, (_, next) {
      if (_searchController.text != next) {
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    final mosques = ref.watch(filteredMosquesProvider);
    final filter = ref.watch(mosqueFilterProvider);
    final isLoading = ref.watch(mosquesLoadingProvider);
    final markers = _buildMarkers(mosques);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: AppColors.accentGreen,
          onPressed: () {
            ActionGuard.execute(
              context: context,
              ref: ref,
              onVolunteerAccess: () => AddMosqueChooserSheet.show(context),
            );
          },
          child: const Icon(Icons.add, color: AppColors.pureWhite),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.abansermon',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Loading overlay while Firestore data arrives
          if (isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Header: back, search, filter chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppStyles.cardShadow,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search,
                                color: AppColors.slate),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => ref
                                    .read(mosqueQueryProvider.notifier)
                                    .state = v,
                                decoration: InputDecoration(
                                  hintText: 'discovery.searchHint'.tr(),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.slate, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(mosqueQueryProvider.notifier)
                                      .state = '';
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FilterRow(current: filter),
              ],
            ),
          ),

          // Recenter button
          PositionedDirectional(
            bottom: 32,
            end: 16,
            child: Material(
              color: AppColors.pureWhite,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    _mapController.move(_initialCenter, _initialZoom),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.my_location,
                      color: AppColors.primaryTeal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final bool isLive;

  const _MapPin({required this.isLive});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? AppColors.accentGreen : AppColors.primaryTeal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pureWhite, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isLive ? Icons.wifi_tethering : Icons.mosque,
            color: AppColors.pureWhite,
            size: 18,
          ),
        ),
        // Pointer triangle
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(width: 12, height: 8, color: color),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FilterRow extends ConsumerWidget {
  final MosqueFilter current;

  const _FilterRow({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, ref, 'discovery.filters.all'.tr(), MosqueFilter.all),
          const SizedBox(width: 8),
          _chip(context, ref, 'discovery.filters.live'.tr(), MosqueFilter.live),
          const SizedBox(width: 8),
          _chip(context, ref, 'discovery.filters.offline'.tr(),
              MosqueFilter.offline),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, WidgetRef ref, String label, MosqueFilter f) {
    final selected = current == f;
    return GestureDetector(
      onTap: () => ref.read(mosqueFilterProvider.notifier).state = f,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppStyles.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.pureWhite : AppColors.slate,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MosqueSheet extends ConsumerWidget {
  final Mosque mosque;

  const _MosqueSheet({required this.mosque});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
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
          Row(
            children: [
              const Icon(Icons.mosque,
                  size: 22, color: AppColors.accentGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mosque.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusBadge(isLive: mosque.isLive),
              const SizedBox(width: 8),
              const Icon(Icons.location_on,
                  size: 16, color: AppColors.slate),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  mosque.address,
                  style: const TextStyle(
                      color: AppColors.slate, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.near_me,
                  size: 14, color: AppColors.slate),
              const SizedBox(width: 4),
              Text(mosque.distance,
                  style: const TextStyle(
                      color: AppColors.slate, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          if (mosque.isLive)
            AppButton(
              label: 'discovery.joinLive'.tr(),
              icon: Icons.live_tv,
              onPressed: () {
                Navigator.pop(context);
                context.push('/live/mock_session_${mosque.id}');
              },
              variant: AppButtonVariant.primary,
            )
          else
            AppButton(
              label: 'discovery.recordSermon'.tr(),
              icon: Icons.mic,
              onPressed: () {
                Navigator.pop(context);
                ActionGuard.execute(
                  context: context,
                  ref: ref,
                  onVolunteerAccess: () =>
                      RecordingTermsSheet.show(context, mosque: mosque),
                );
              },
              variant: AppButtonVariant.primary,
            ),
          const SizedBox(height: 12),
          AppButton(
            label: 'common.cancel'.tr(),
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.tertiary,
            isFullWidth: false,
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            const Icon(Icons.wifi_tethering,
                size: 12, color: AppColors.pureWhite),
            const SizedBox(width: 4),
          ],
          Text(
            isLive
                ? 'discovery.filters.live'.tr()
                : 'discovery.filters.offline'.tr(),
            style: TextStyle(
              color: isLive ? AppColors.pureWhite : AppColors.slate,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
