import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/providers/location_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/action_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../data/mosque_repository.dart';
import '../domain/mosque.dart';
import 'widgets/add_mosque_chooser_sheet.dart';
import 'widgets/recording_terms_sheet.dart';

// Height of the slide-up mosque detail panel.
const double _kPanelHeight = 270.0;

class MosqueMapScreen extends ConsumerStatefulWidget {
  const MosqueMapScreen({super.key});

  @override
  ConsumerState<MosqueMapScreen> createState() => _MosqueMapScreenState();
}

class _MosqueMapScreenState extends ConsumerState<MosqueMapScreen> {
  static const LatLng _riyadhCenter = LatLng(24.7136, 46.6753);
  static const double _defaultZoom = 11.5;

  final MapController _mapController = MapController();
  late final TextEditingController _searchController;
  Mosque? _selectedMosque;

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

  void _selectMosque(Mosque mosque) {
    setState(() => _selectedMosque = mosque);
    _mapController.move(LatLng(mosque.lat, mosque.lng), 14.5);
  }

  void _dismissPanel() => setState(() => _selectedMosque = null);

  void _flyToUser() async {
    final pos = ref.read(userLocationProvider).valueOrNull;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14.0);
    } else {
      _mapController.move(_riyadhCenter, _defaultZoom);
    }
  }

  List<Marker> _buildMarkers(List<Mosque> mosques) {
    return [
      for (final m in mosques)
        Marker(
          key: ValueKey(m.id),
          point: LatLng(m.lat, m.lng),
          width: 56,
          height: 66,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _selectMosque(m),
            child: _MapPin(
              key: ValueKey('pin_${m.id}'),
              isLive: m.isLive,
              isSelected: _selectedMosque?.id == m.id,
            ),
          ),
        ),
    ];
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
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final panelVisible = _selectedMosque != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrlBg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final userPos = ref.watch(userLocationProvider).valueOrNull;
    final userLatLng = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _riyadhCenter,
              initialZoom: _defaultZoom,
              minZoom: 3,
              maxZoom: 19,
              onTap: (_, __) => _dismissPanel(),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.abansermon',
                maxZoom: 19,
                tileBuilder: (ctx, tileWidget, tile) => ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.52, 0.00, 0.05, 0.0, 0.0,
                    0.00, 0.52, 0.00, 0.0, 0.0,
                    0.05, 0.00, 0.60, 0.0, 0.0,
                    0.00, 0.00, 0.00, 1.0, 0.0,
                  ]),
                  child: tileWidget,
                ),
              ),
              // User location accuracy halo
              if (userLatLng != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: userLatLng,
                    radius: 40,
                    useRadiusInMeter: true,
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    borderColor: AppColors.primaryTeal.withValues(alpha: 0.35),
                    borderStrokeWidth: 1.5,
                  ),
                ]),
              MarkerLayer(markers: markers),
              // User location dot (on top of mosque markers)
              if (userLatLng != null)
                MarkerLayer(markers: [
                  Marker(
                    point: userLatLng,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.pureWhite, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal
                                .withValues(alpha: 0.45),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
            ],
          ),

          // ── Loading overlay ─────────────────────────────────────────
          if (isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // ── Slide-up mosque detail panel ─────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            bottom: panelVisible ? 0 : -(_kPanelHeight + 40),
            left: 0,
            right: 0,
            child: panelVisible
                ? _MosquePanel(
                    mosque: _selectedMosque!,
                    onDismiss: _dismissPanel,
                    onNavigate: () => _selectMosque(_selectedMosque!),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Glassmorphism header ─────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: _MapHeader(
              searchController: _searchController,
              currentFilter: filter,
              mosqueCount: mosques.length,
              liveCount: mosques.where((m) => m.isLive).length,
            ),
          ),

          // ── Right-side map controls ──────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: panelVisible
                ? _kPanelHeight + 16 + bottomPad
                : 100 + bottomPad,
            child: _MapControls(
              onZoomIn: () => _mapController.move(
                _mapController.camera.center,
                (_mapController.camera.zoom + 1).clamp(3, 19),
              ),
              onZoomOut: () => _mapController.move(
                _mapController.camera.center,
                (_mapController.camera.zoom - 1).clamp(3, 19),
              ),
              onLocate: _flyToUser,
              onReset: () =>
                  _mapController.move(_riyadhCenter, _defaultZoom),
            ),
          ),

          // ── Left-side add mosque button ───────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 16,
            bottom: panelVisible
                ? _kPanelHeight + 16 + bottomPad
                : 100 + bottomPad,
            child: _ControlBtn(
              icon: Icons.add_location_alt_rounded,
              bg: ctrlBg,
              iconColor: AppColors.accentGreen,
              onTap: () => ActionGuard.execute(
                context: context,
                ref: ref,
                onVolunteerAccess: () => AddMosqueChooserSheet.show(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glassmorphism search + filter header
// ─────────────────────────────────────────────────────────────────────────────

class _MapHeader extends ConsumerWidget {
  final TextEditingController searchController;
  final MosqueFilter currentFilter;
  final int mosqueCount;
  final int liveCount;

  const _MapHeader({
    required this.searchController,
    required this.currentFilter,
    required this.mosqueCount,
    required this.liveCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.secondaryDarkBg.withValues(alpha: 0.88)
                : AppColors.pureWhite.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
            ),
            boxShadow: AppStyles.elevatedShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search row
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SearchField(controller: searchController),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filter chips + count badge
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'discovery.filters.all'.tr(),
                            icon: Icons.grid_view_rounded,
                            filter: MosqueFilter.all,
                            current: currentFilter,
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'discovery.filters.live'.tr(),
                            icon: Icons.wifi_tethering,
                            filter: MosqueFilter.live,
                            current: currentFilter,
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'discovery.filters.offline'.tr(),
                            icon: Icons.mosque,
                            filter: MosqueFilter.offline,
                            current: currentFilter,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (liveCount > 0) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '$mosqueCount',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : AppColors.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.doveGray.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.slate, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (v) =>
                  ref.read(mosqueQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'discovery.searchHint'.tr(),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                ref.read(mosqueQueryProvider.notifier).state = '';
              },
              child: const Icon(Icons.cancel,
                  color: AppColors.slate, size: 16),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final IconData icon;
  final MosqueFilter filter;
  final MosqueFilter current;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.filter,
    required this.current,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = current == filter;
    return GestureDetector(
      onTap: () => ref.read(mosqueFilterProvider.notifier).state = filter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryTeal
              : AppColors.primaryTeal.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryTeal
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: AppColors.pureWhite,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map control buttons (zoom ± / locate / reset)
// ─────────────────────────────────────────────────────────────────────────────

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocate;
  final VoidCallback onReset;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final fg = isDark ? AppColors.pureWhite : AppColors.primaryTeal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlBtn(icon: Icons.add, bg: bg, iconColor: fg, onTap: onZoomIn),
        const SizedBox(height: 2),
        _ControlBtn(icon: Icons.remove, bg: bg, iconColor: fg, onTap: onZoomOut),
        const SizedBox(height: 8),
        _ControlBtn(
          icon: Icons.my_location_rounded,
          bg: bg,
          iconColor: fg,
          onTap: onLocate,
        ),
        const SizedBox(height: 8),
        _ControlBtn(
          icon: Icons.explore_outlined,
          bg: bg,
          iconColor: fg,
          onTap: onReset,
        ),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.bg,
    this.iconColor = AppColors.pureWhite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: Colors.white30,
        highlightColor: Colors.white12,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated map pin
// ─────────────────────────────────────────────────────────────────────────────

class _MapPin extends StatefulWidget {
  final bool isLive;
  final bool isSelected;

  const _MapPin({
    super.key,
    required this.isLive,
    required this.isSelected,
  });

  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 2.8).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    if (widget.isLive) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_MapPin old) {
    super.didUpdateWidget(old);
    if (widget.isLive && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.isLive && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isLive ? AppColors.accentGreen : AppColors.primaryTeal;
    final pinSize = widget.isSelected ? 44.0 : 36.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: pinSize,
          height: pinSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Pulse ring — drawn behind the pin without affecting layout.
              if (widget.isLive)
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => SizedBox(
                        width: pinSize * _pulseScale.value,
                        height: pinSize * _pulseScale.value,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentGreen
                                .withValues(alpha: _pulseOpacity.value * 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Pin body
              AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              width: pinSize,
              height: pinSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.pureWhite,
                  width: widget.isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                        alpha: widget.isSelected ? 0.6 : 0.3),
                    blurRadius: widget.isSelected ? 14 : 6,
                    offset: const Offset(0, 3),
                    spreadRadius: widget.isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.isLive ? Icons.wifi_tethering : Icons.mosque,
                color: AppColors.pureWhite,
                size: widget.isSelected ? 22 : 17,
              ),
            ),
          ],
          ),
        ),
        // Pointer
        ClipPath(
          clipper: _TriangleClipper(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 12,
            height: 8,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width / 2, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide-up mosque detail panel
// ─────────────────────────────────────────────────────────────────────────────

class _MosquePanel extends ConsumerWidget {
  final Mosque mosque;
  final VoidCallback onDismiss;
  final VoidCallback onNavigate;

  const _MosquePanel({
    required this.mosque,
    required this.onDismiss,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: _kPanelHeight + bottomPad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle + dismiss
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.doveGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.slate),
                  ),
                ),
              ],
            ),
          ),

          // Mosque name + status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    mosque.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(isLive: mosque.isLive),
              ],
            ),
          ),

          // Address + distance
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.slate),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mosque.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.slate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mosque.distance,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Imam name (if available)
          if (mosque.imamName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.slate),
                  const SizedBox(width: 4),
                  Text(
                    mosque.imamName!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.slate),
                  ),
                ],
              ),
            ),

          // Sermon topic chip (if available)
          if (mosque.topic != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              AppColors.accentGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_outlined,
                              size: 12, color: AppColors.accentGreen),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              mosque.topic!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Action buttons
          Padding(
            padding:
                EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
            child: Row(
              children: [
                // Navigate — fly to mosque on map
                Material(
                  color: AppColors.primaryTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onNavigate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 16, color: AppColors.primaryTeal),
                          SizedBox(width: 6),
                          Text(
                            'Navigate',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Primary CTA
                Expanded(
                  child: mosque.isLive
                      ? AppButton(
                          label: 'discovery.joinLive'.tr(),
                          icon: Icons.live_tv_rounded,
                          onPressed: () =>
                              context.push('/live/mock_session_${mosque.id}'),
                          variant: AppButtonVariant.primary,
                        )
                      : AppButton(
                          label: 'discovery.recordSermon'.tr(),
                          icon: Icons.mic_rounded,
                          onPressed: () => ActionGuard.execute(
                            context: context,
                            ref: ref,
                            onVolunteerAccess: () =>
                                RecordingTermsSheet.show(context,
                                    mosque: mosque),
                          ),
                          variant: AppButtonVariant.primary,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatefulWidget {
  final bool isLive;
  const _StatusBadge({required this.isLive});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
    );
    if (widget.isLive) _blink.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isLive
        ? 'discovery.filters.live'.tr()
        : 'discovery.filters.offline'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isLive
            ? AppColors.accentGreen.withValues(alpha: 0.12)
            : AppColors.doveGray.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isLive
              ? AppColors.accentGreen.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLive)
            AnimatedBuilder(
              animation: _blink,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: widget.isLive
                  ? AppColors.accentGreen
                  : AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}
