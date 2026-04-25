import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> archive = [
      {
        'title': 'Patience in Times of Trial',
        'mosque': 'Al-Noor Mosque',
        'date': 'Feb 7, 2026'
      },
      {
        'title': 'The Power of Gratitude',
        'mosque': 'Masjid Al-Iman',
        'date': 'Jan 31, 2026'
      },
      {
        'title': 'Brotherhood in Islam',
        'mosque': 'Islamic Center',
        'date': 'Jan 24, 2026'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khutbah Archive'),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppStyles.cardShadow,
                border: Border.all(color: AppColors.doveGray),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search by title or mosque...',
                  icon: Icon(Icons.search, color: AppColors.slate),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...archive.map((a) {
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
                        color: AppColors.cloud,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: AppColors.accentGreen),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title']!,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(a['mosque']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 12, color: AppColors.slate),
                              const SizedBox(width: 4),
                              Text(a['date']!,
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.slate)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
