import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../data/mosque_repository.dart';
import '../domain/mosque.dart';

class AddMosqueMapScreen extends ConsumerStatefulWidget {
  const AddMosqueMapScreen({super.key});

  @override
  ConsumerState<AddMosqueMapScreen> createState() =>
      _AddMosqueMapScreenState();
}

class _AddMosqueMapScreenState extends ConsumerState<AddMosqueMapScreen> {
  static const LatLng _initialCenter = LatLng(24.7136, 46.6753);
  static const double _initialZoom = 12.0;

  final MapController _mapController = MapController();
  LatLng _pickedLocation = _initialCenter;

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _pickedLocation = camera.center;
  }

  Future<void> _confirm() async {
    final created = await AppBottomSheet.show<Mosque>(
      context,
      title: 'discovery.addMosque.details'.tr(),
      child: _DetailsSheet(location: _pickedLocation),
    );

    if (!mounted || created == null) return;
    try {
      await ref.read(mosqueRepositoryProvider.notifier).addMosque(created);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('discovery.addMosque.saved'.tr())),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 3,
              maxZoom: 18,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.abansermon',
              ),
            ],
          ),

          // Center pin overlay — bottom padding equals half the icon height so
          // the pin tip sits exactly on the camera target.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: AppColors.accentGreen,
                  shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'discovery.addMosque.pickLocation'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'discovery.addMosque.moveMapHint'.tr(),
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recenter button
          PositionedDirectional(
            bottom: 120,
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

          // Confirm CTA
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: AppButton(
              label: 'discovery.addMosque.confirmLocation'.tr(),
              onPressed: _confirm,
              variant: AppButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSheet extends StatefulWidget {
  final LatLng location;

  const _DetailsSheet({required this.location});

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mosque = Mosque(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      lat: widget.location.latitude,
      lng: widget.location.longitude,
      status: MosqueStatus.inactive,
      distance: '— كم',
    );
    Navigator.of(context).pop(mosque);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: mq.viewInsets.bottom,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              controller: _nameController,
              label: 'discovery.addMosque.name'.tr(),
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _addressController,
              label: 'discovery.addMosque.address'.tr(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'discovery.addMosque.save'.tr(),
              onPressed: _submit,
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _Field({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      validator: (v) => (v == null || v.trim().isEmpty) ? '—' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? AppColors.secondaryDarkBg : AppColors.cloud,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
