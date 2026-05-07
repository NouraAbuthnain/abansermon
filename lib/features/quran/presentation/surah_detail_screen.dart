import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_back_button.dart';
import '../domain/quran_models.dart';
import '../data/quran_repository.dart';
import 'package:easy_localization/easy_localization.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranRepository _repository = QuranRepository();
  late Future<SurahDetail> _surahFuture;

  @override
  void initState() {
    super.initState();
    _surahFuture = _repository.getSurahDetail(widget.surahNumber);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('services.quran.title'.tr(), 
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold, 
            fontSize: 18,
            color: isDark ? AppColors.pureWhite : AppColors.ink,
          )),
        leading: AppBackButton(),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<SurahDetail>(
        future: _surahFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          }

          final surah = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: surah.ayahs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSurahHeader(surah);
              }
              final ayah = surah.ayahs[index - 1];
              return _buildAyahItem(ayah, surah.number);
            },
          );
        },
      ),
    );
  }

  Widget _buildSurahHeader(SurahDetail surah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24, top: 4),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppStyles.elevatedShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'services.quran.surahPrefix'.tr()}${surah.englishName}',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'services.quran.englishPrefix'.tr()}${surah.englishNameTranslation}',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${'services.quran.versesPrefix'.tr()}${surah.numberOfAyahs}',
                          style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 10, color: Colors.white24),
                        const SizedBox(width: 12),
                        Text(
                          '${'services.quran.revealedInPrefix'.tr()}${'services.quran.${surah.revelationType.toLowerCase()}'.tr()}',
                          style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                surah.name,
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (surah.number != 1 && surah.number != 9)
          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 8),
            child: Text(
              'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: GoogleFonts.amiri(
                color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildAyahItem(Ayah ayah, int surahNumber) {
    String ayahText = ayah.text;
    if (ayah.numberInSurah == 1 && surahNumber != 1 && surahNumber != 9) {
      const bismillah = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
      if (ayahText.startsWith(bismillah)) {
        ayahText = ayahText.replaceFirst(bismillah, "").trim();
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E20) : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.secondaryDarkBg : AppColors.cloud,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.primaryTeal.withOpacity(0.3) : AppColors.greenMist, width: 1),
                ),
                child: Center(
                  child: Text(
                    '${ayah.numberInSurah}',
                    style: GoogleFonts.cairo(
                      color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: AppColors.doveGray, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ayahText,
            textAlign: TextAlign.right,
            textDirection: ui.TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 26,
              height: 2.2,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.pureWhite : AppColors.ink,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            ayah.translation,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.slate,
              height: 1.6,
            ),
          ),
        ],
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
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('services.quran.failedToLoad'.tr(), 
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, 
              style: const TextStyle(color: AppColors.slate, fontSize: 12)),
            const SizedBox(height: 24),
            AppButton(
              label: 'services.quran.retry'.tr(),
              onPressed: () {
                setState(() {
                  _surahFuture = _repository.getSurahDetail(widget.surahNumber);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

