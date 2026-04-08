import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/mosque_card.dart';
import '../../../core/widgets/app_back_button.dart';

class MosquesScreen extends StatelessWidget {
  const MosquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nearby Mosques'),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
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

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Live', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Offline', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Map Placeholder
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
                      Text('Map View',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.slate)),
                    ],
                  ),
                ),
              ),

              // Results
              ...mosques.map((m) {
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentGreen,
        onPressed: () {},
        child: const Icon(Icons.add, color: AppColors.pureWhite),
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
