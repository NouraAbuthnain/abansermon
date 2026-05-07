import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../domain/quran_models.dart';
import '../data/quran_repository.dart';
import 'surah_detail_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final QuranRepository _repository = QuranRepository();
  late Future<List<Surah>> _surahsFuture;
  List<Surah>? _allSurahs;
  List<Surah>? _filteredSurahs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _surahsFuture = _repository.getSurahList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Remove harakat/tashkeel
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  void _filterSurahs(String query) {
    if (_allSurahs == null) return;
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = _allSurahs;
      } else {
        final queryLower = query.toLowerCase();
        final normalizedQuery = _normalizeArabic(query);
        
        _filteredSurahs = _allSurahs!
            .where((surah) =>
                surah.englishName.toLowerCase().contains(queryLower) ||
                surah.englishNameTranslation.toLowerCase().contains(queryLower) ||
                _normalizeArabic(surah.name).contains(normalizedQuery) ||
                surah.number.toString().contains(queryLower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: Text('The Holy Quran',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20)),
        leading: const AppBackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(isDark),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Surah>>(
              future: _surahsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal));
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No surahs found'));
                }

                _allSurahs ??= snapshot.data;
                _filteredSurahs ??= _allSurahs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _filteredSurahs!.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildBismillahCard();
                    }
                    final surah = _filteredSurahs![index - 1];
                    return _buildSurahItem(surah);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSurahs,
        decoration: InputDecoration(
          hintText: 'Search Surah (English or Arabic)...',
          hintStyle: GoogleFonts.cairo(color: AppColors.slate, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryTeal, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.slate),
                  onPressed: () {
                    _searchController.clear();
                    _filterSurahs('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBismillahCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 4),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppStyles.elevatedShadow,
      ),
      child: Column(
        children: [
          Text(
            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
            style: GoogleFonts.amiri(
                color: Colors.white.withOpacity(0.95),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'In the name of Allah, the Most Gracious, the Most Merciful',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahItem(Surah surah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahDetailScreen(
                  surahNumber: surah.number,
                  surahName: surah.englishName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                _buildSurahNumberIcon(surah.number),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.englishName,
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, 
                            fontSize: 17,
                            color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.revelationType.toUpperCase()} · ${surah.numberOfAyahs} VERSES',
                        style: GoogleFonts.cairo(
                            color: AppColors.slate, 
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  surah.name,
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahNumberIcon(int number) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greenMist, width: 1),
      ),
      child: Center(
        child: Text(
          '$number',
          style: GoogleFonts.cairo(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
              fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.doveGray),
            const SizedBox(height: 20),
            Text(
              'Failed to load Quran',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _surahsFuture = _repository.getSurahList();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


