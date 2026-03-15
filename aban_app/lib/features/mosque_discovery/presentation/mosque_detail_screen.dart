import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MosqueDetailScreen extends StatefulWidget {
  final String id;
  const MosqueDetailScreen({super.key, required this.id});

  @override
  State<MosqueDetailScreen> createState() => _MosqueDetailScreenState();
}

class _MosqueDetailScreenState extends State<MosqueDetailScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 60, left: 20, right: 20, bottom: 24),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.pureWhite),
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.pureWhite.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Al-Noor Mosque",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppColors.pureWhite,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 8, color: AppColors.pureWhite),
                                    SizedBox(width: 4),
                                    Text('Live',
                                        style: TextStyle(
                                            color: AppColors.pureWhite,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: AppColors.doveGray),
                              const SizedBox(width: 4),
                              Text(
                                "123 Main St, Downtown",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.doveGray),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Imam: Sheikh Ahmad",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.doveGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: AppColors.accentGreen),
                        const SizedBox(width: 6),
                        Text(
                          "Dhuhr – 12:30 PM",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.pureWhite),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTab(0, 'Arabic'),
                        _buildTab(1, 'English'),
                        _buildTab(2, 'Info'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedTabIndex == 0) ...[
                    // Transcript
                    _buildTranscriptCard("بسم الله الرحمن الرحيم", "Verse 1"),
                    _buildTranscriptCard(
                        "الحمد لله رب العالمين والصلاة والسلام على أشرف المرسلين",
                        "Verse 2"),
                  ] else if (_selectedTabIndex == 1) ...[
                    // Translation
                    _buildTranscriptCard(
                        "In the name of Allah, the Most Gracious, the Most Merciful",
                        "Line 1"),
                    _buildTranscriptCard(
                        "All praise is due to Allah, Lord of all worlds, and peace be upon the noblest of messengers",
                        "Line 2"),
                  ] else ...[
                    // Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("About",
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            "A vibrant community mosque serving the downtown area with daily prayers, Friday khutbahs, and educational programs.",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(String text, String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            textAlign:
                _selectedTabIndex == 0 ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: _selectedTabIndex == 0 ? 'Cairo' : null,
                  height: 1.5,
                ),
            textDirection:
                _selectedTabIndex == 0 ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.slate)),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.pureWhite : AppColors.slate,
            ),
          ),
        ),
      ),
    );
  }
}
