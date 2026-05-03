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
  final FocusNode _searchFocus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(mosqueQueryProvider);
    _searchFocus.addListener(() {
      setState(() => _isFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = ref.watch(filteredMosquesProvider);
    final filter = ref.watch(mosqueFilterProvider);
    final isLoading = ref.watch(mosquesLoadingProvider);

    final navBarHeight = NavBarHeight.of(context);
    const fabSize = 56.0;
    const fabGap = 16.0;
    final fabBottomPadding = navBarHeight + fabGap;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        padding: EdgeInsets.only(bottom: navBarHeight + fabSize + fabGap * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Search
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFocused
                      ? AppColors.primaryTeal.withValues(alpha: 0.5)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.transparent),
                  width: 1.5,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : (isDark ? [] : AppStyles.cardShadow),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) =>
                    ref.read(mosqueQueryProvider.notifier).state = v,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'discovery.searchHint'.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.slate.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Image.asset(
                      'assets/icons/search.png',
                      width: 18,
                      height: 18,
                      color: _isFocused ? AppColors.primaryTeal : AppColors.slate,
                    ),
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            color: AppColors.slate.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(mosqueQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
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
            ),
            const SizedBox(height: 12),

            // Mini map preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => context.push('/map'),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.accentGreen.withValues(alpha: 0.05)
                        : AppColors.greenMist.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: isDark 
                        ? Border.all(color: AppColors.accentGreen.withValues(alpha: 0.1))
                        : null,
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
            ),
            const SizedBox(height: 24),

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected 
              ? AppColors.primaryTeal 
              : (isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected ? [] : (isDark ? [] : AppStyles.cardShadow),
          border: Border.all(
            color: selected 
                ? AppColors.primaryTeal 
                : (isDark ? AppColors.doveGray.withValues(alpha: 0.1) : AppColors.cloud),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected 
                ? AppColors.pureWhite 
                : (isDark ? AppColors.doveGray : AppColors.slate),
          ),
        ),
      ),
    );
  }
}
