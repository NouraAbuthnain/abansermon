import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/mosque_card.dart';
import '../../../core/presentation/widgets/scaffold_with_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/utils/action_guard.dart';
import '../data/mosque_repository.dart';
import '../domain/mosque.dart';
import 'widgets/add_mosque_chooser_sheet.dart';

class MosquesScreen extends ConsumerStatefulWidget {
  const MosquesScreen({super.key});

  @override
  ConsumerState<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends ConsumerState<MosquesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(mosqueQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    // Triggers permission dialog immediately when the screen opens.
    ref.watch(userLocationProvider);

    final filtered = ref.watch(filteredMosquesProvider);
    final filter = ref.watch(mosqueFilterProvider);
    final isLoading = ref.watch(mosquesLoadingProvider);

    final navBarHeight = NavBarHeight.of(context);
    const fabSize = 56.0;
    const fabGap = 16.0;
    final fabBottomPadding = navBarHeight + fabGap;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomPadding),
        child: FloatingActionButton(
          backgroundColor: AppColors.accentGreen,
          elevation: 4,
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
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, navBarHeight + fabSize + fabGap * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppStyles.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(mosqueQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'discovery.searchHint'.tr(),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.slate),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.slate, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(mosqueQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'discovery.filters.all'.tr(),
                    selected: filter == MosqueFilter.all,
                    onTap: () => ref
                        .read(mosqueFilterProvider.notifier)
                        .state = MosqueFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'discovery.filters.live'.tr(),
                    selected: filter == MosqueFilter.live,
                    onTap: () => ref
                        .read(mosqueFilterProvider.notifier)
                        .state = MosqueFilter.live,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'discovery.filters.offline'.tr(),
                    selected: filter == MosqueFilter.offline,
                    onTap: () => ref
                        .read(mosqueFilterProvider.notifier)
                        .state = MosqueFilter.offline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mini map preview → tapping opens full map
            GestureDetector(
              onTap: () => context.push('/map'),
              child: Container(
                height: 140,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.greenMist.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on,
                        size: 32, color: AppColors.accentGreen),
                    const SizedBox(height: 8),
                    Text(
                      'discovery.openMap'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
            ),

            // Results
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'discovery.emptyResults'.tr(),
                    style: const TextStyle(color: AppColors.slate),
                  ),
                ),
              )
            else
              ...filtered.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MosqueRow(mosque: m),
                  )),
          ],
        ),
      ),
    );
  }
}

class _MosqueRow extends ConsumerWidget {
  final Mosque mosque;

  const _MosqueRow({required this.mosque});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MosqueCardWidget(
      name: mosque.name,
      address: mosque.address,
      distance: mosque.distance,
      status: mosque.status,
      onTap: () => context.push('/mosque/${mosque.id}'),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primaryTeal : AppColors.doveGray),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.pureWhite : AppColors.slate,
          ),
        ),
      ),
    );
  }
}
