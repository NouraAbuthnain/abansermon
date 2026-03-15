import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _tab = 'read'; // 'read' or 'listen'

  final List<Map<String, dynamic>> _surahs = [
    {
      "number": 1,
      "name": "Al-Fatiha",
      "arabic": "الفاتحة",
      "verses": 7,
      "type": "Meccan"
    },
    {
      "number": 2,
      "name": "Al-Baqarah",
      "arabic": "البقرة",
      "verses": 286,
      "type": "Medinan"
    },
    {
      "number": 3,
      "name": "Ali 'Imran",
      "arabic": "آل عمران",
      "verses": 200,
      "type": "Medinan"
    },
    {
      "number": 36,
      "name": "Ya-Sin",
      "arabic": "يس",
      "verses": 83,
      "type": "Meccan"
    },
    {
      "number": 55,
      "name": "Ar-Rahman",
      "arabic": "الرحمن",
      "verses": 78,
      "type": "Medinan"
    },
    {
      "number": 67,
      "name": "Al-Mulk",
      "arabic": "الملك",
      "verses": 30,
      "type": "Meccan"
    },
    {
      "number": 112,
      "name": "Al-Ikhlas",
      "arabic": "الإخلاص",
      "verses": 4,
      "type": "Meccan"
    },
    {
      "number": 113,
      "name": "Al-Falaq",
      "arabic": "الفلق",
      "verses": 5,
      "type": "Meccan"
    },
    {
      "number": 114,
      "name": "An-Nas",
      "arabic": "الناس",
      "verses": 6,
      "type": "Meccan"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('Quran Access',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: BackButton(onPressed: () => context.pop()),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Read, listen, and explore the Holy Quran',
              style: TextStyle(color: AppColors.slate, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Bismillah Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppStyles.elevatedShadow,
              ),
              child: Column(
                children: [
                  Text(
                    'بسم الله الرحمن الرحيم',
                    style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'Amiri'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'In the name of Allah, the Most Gracious, the Most Merciful',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Row(
                children: [
                  _buildTab('read', 'Read', Icons.menu_book),
                  _buildTab('listen', 'Listen', Icons.headset),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Surah list
            ..._surahs.map((surah) => _buildSurahItem(surah)).toList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String key, String label, IconData icon) {
    bool isSelected = _tab == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? AppColors.pureWhite : AppColors.slate),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.pureWhite : AppColors.slate,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahItem(Map<String, dynamic> surah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.greenMist,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${surah['number']}',
                      style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${surah['type']} · ${surah['verses']} verses',
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  surah['arabic'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri', // Adjust font later if needed
                  ),
                ),
                if (_tab == 'listen') ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow,
                          size: 16, color: AppColors.accentGreen),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
