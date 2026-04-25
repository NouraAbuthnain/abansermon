import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/mosque_card.dart';
import '../../../core/presentation/widgets/scaffold_with_nav.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/action_guard.dart';
import 'widgets/mosque_selection_sheet.dart';

class MosquesScreen extends ConsumerWidget {
  const MosquesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Map<String, dynamic>> mosques = [
      {
        "name": "Al-Noor Mosque",
        "address": "123 Main St, Downtown",
        "distance": "0.5 km",
        "status": MosqueStatus.active,
        "nextPrayer": "Dhuhr – 12:30 PM",
        "id": "1"
      },
      {
        "name": "Masjid Al-Iman",
        "address": "456 Oak Ave, Midtown",
        "distance": "1.2 km",
        "status": MosqueStatus.active,
        "nextPrayer": "Dhuhr – 12:35 PM",
        "id": "2"
      },
      {
        "name": "Islamic Center",
        "address": "789 Cedar Rd, Uptown",
        "distance": "2.8 km",
        "status": MosqueStatus.inactive,
        "nextPrayer": "Dhuhr – 12:30 PM",
        "id": "3"
      },
      {
        "name": "Masjid As-Salam",
        "address": "321 Pine St, Eastside",
        "distance": "3.1 km",
        "status": MosqueStatus.pending,
        "nextPrayer": "Dhuhr – 12:40 PM",
        "id": "4"
      },
    ];

    final isVolunteer = ref.watch(authProvider).role == UserRole.volunteer;

    // Filter out pending mosques for guests.
    final visibleMosques = isVolunteer
        ? mosques
        : mosques.where((m) => m['status'] != MosqueStatus.pending).toList();

    // The total height of the bottom nav bar (content + system inset).
    // This is broadcast by ScaffoldWithNavBar via NavBarHeight.
    // We use it to:
    //   1. Pad the scroll view so the last card isn't hidden behind the bar.
    //   2. Lift the FAB above the bar via floatingActionButtonAnimator /
    //      Padding — the most reliable cross-platform approach when the FAB
    //      is in a nested Scaffold.
    final double navBarHeight = NavBarHeight.of(context);

    // FAB size (56) + gap above nav bar (16) + nav bar height.
    const double fabSize = 56.0;
    const double fabGap = 16.0;
    final double fabBottomPadding = navBarHeight + fabGap;

    return Scaffold(
      // ── IMPORTANT ─────────────────────────────────────────────────────────
      // backgroundColor must be transparent so the outer Scaffold's colour
      // shows through; otherwise we get a double background flicker.
      backgroundColor: Colors.transparent,

      // extendBody on the inner Scaffold is NOT needed — extendBody is already
      // set on the outer ScaffoldWithNavBar. Setting it here again would break
      // the FAB auto-positioning.
      //
      // floatingActionButtonLocation: we use endFloat (default) and push the
      // FAB up with padding so it clears the nav bar. This is more reliable
      // than endDocked when a custom nav bar widget is used.
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
              onVolunteerAccess: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MosqueSelectionSheet(mosques: mosques),
                );
              },
            );
          },
          child: const Icon(Icons.add, color: AppColors.pureWhite),
        ),
      ),

      body: SingleChildScrollView(
        // Bottom padding = nav bar height so the last card is never hidden
        // behind the bar when the user scrolls to the bottom.
        padding: EdgeInsets.fromLTRB(20, 20, 20, navBarHeight + fabSize + fabGap * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppStyles.cardShadow,
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or location...',
                  prefixIcon: Icon(Icons.search, color: AppColors.slate),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // ── Filters ─────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Live', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Offline', false),
                  if (isVolunteer) ...[
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', false),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Map placeholder ──────────────────────────────────────
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
                      'Map View',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
            ),

            // ── Results ─────────────────────────────────────────────
            ...visibleMosques.map((m) {
              return GestureDetector(
                onTap: () => context.push('/mosque/${m['id']}'),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: MosqueCardWidget(
                    name: m['name'],
                    address: m['address'],
                    distance: m['distance'],
                    status: m['status'],
                    nextPrayer: m['nextPrayer'],
                    onTap: () => context.push('/mosque/${m['id']}'),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryTeal : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.doveGray),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppColors.pureWhite : AppColors.slate,
        ),
      ),
    );
  }
}
