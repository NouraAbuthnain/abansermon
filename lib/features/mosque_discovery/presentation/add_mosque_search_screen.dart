import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:geolocator/geolocator.dart';
import '../../../core/presentation/widgets/mosque_card.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../data/mosque_repository.dart';
import '../data/riyadh_mosques_reference.dart';
import '../domain/mosque.dart';

class AddMosqueSearchScreen extends ConsumerStatefulWidget {
  const AddMosqueSearchScreen({super.key});

  @override
  ConsumerState<AddMosqueSearchScreen> createState() =>
      _AddMosqueSearchScreenState();
}

class _AddMosqueSearchScreenState extends ConsumerState<AddMosqueSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Mosque> _results(Position? userPos) {
    final q = _query.trim().toLowerCase();
    Iterable<Mosque> list = kRiyadhMosquesReference;
    if (q.isNotEmpty) {
      list = list.where((m) =>
          m.name.toLowerCase().contains(q) ||
          m.address.toLowerCase().contains(q));
    }
    return list.map((m) {
      if (userPos == null) return m;
      final meters = Geolocator.distanceBetween(
          userPos.latitude, userPos.longitude, m.lat, m.lng);
      final label = meters < 1000
          ? '${meters.round()} m'
          : '${(meters / 1000).toStringAsFixed(1)} km';
      return m.copyWith(distance: label);
    }).toList()
      ..sort((a, b) {
        if (userPos == null) return 0;
        final da = Geolocator.distanceBetween(
            userPos.latitude, userPos.longitude, a.lat, a.lng);
        final db = Geolocator.distanceBetween(
            userPos.latitude, userPos.longitude, b.lat, b.lng);
        return da.compareTo(db);
      });
  }

  Future<void> _selectMosque(Mosque mosque) async {
    // Write to Firestore only if not already there.
    await ref.read(mosqueRepositoryProvider.notifier).addMosque(mosque);
    if (!mounted) return;
    context.pop();
    context.push('/mosque/${mosque.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodyMedium?.color;
    final userPos = ref.watch(userLocationProvider).valueOrNull;
    final results = _results(userPos);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'discovery.addMosque.searchExisting'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'discovery.addMosque.searchHint'.tr(),
                    hintStyle: TextStyle(color: mutedColor),
                    prefixIcon: Icon(Icons.search, color: mutedColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'discovery.emptyResults'.tr(),
                        style: TextStyle(color: mutedColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final m = results[index];
                        return MosqueCardWidget(
                          mosque: m,
                          onTap: () => _selectMosque(m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
