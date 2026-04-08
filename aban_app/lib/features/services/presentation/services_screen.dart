import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.translate,
        'title': 'Live Translation',
        'subtitle': 'Real-time khutbah translation in 12+ languages',
        'route': '/live/default',
        'badge': 'Popular'
      },
      {
        'icon': Icons.archive_outlined,
        'title': 'Khutbah Archive',
        'subtitle': 'Browse past khutbahs with full transcripts',
        'route': '/archive'
      },
      {
        'icon': Icons.menu_book,
        'title': 'Quran Access',
        'subtitle': 'Read, listen, and explore the Holy Quran',
        'route': '/quran'
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'AI Summary',
        'subtitle': 'Get key points from any khutbah instantly',
        'badge': 'New'
      },
      {
        'icon': Icons.mic,
        'title': 'Live Transcription',
        'subtitle': 'Follow along with real-time text of the khutbah',
        'route': '/live/default'
      },
      {
        'icon': Icons.note_alt_outlined,
        'title': 'Notes',
        'subtitle': 'Save personal notes during the khutbah'
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Services'),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ...services.map((s) {
              return GestureDetector(
                onTap: () {
                  if (s['route'] != null) {
                    context.push(s['route']);
                  }
                },
                child: Container(
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
                        child: Icon(s['icon'], color: AppColors.accentGreen),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  s['title'],
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                if (s['badge'] != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s['badge'],
                                      style: const TextStyle(
                                        color: AppColors.accentGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['subtitle'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.slate),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
