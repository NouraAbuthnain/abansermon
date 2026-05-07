import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../domain/mosque.dart';

class KhutbahDetailScreen extends ConsumerStatefulWidget {
  final ArchivedKhutbah khutbah;
  const KhutbahDetailScreen({super.key, required this.khutbah});

  @override
  ConsumerState<KhutbahDetailScreen> createState() => _KhutbahDetailScreenState();
}

class _KhutbahDetailScreenState extends ConsumerState<KhutbahDetailScreen> {
  late AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    if (widget.khutbah.audioUrl != null && widget.khutbah.audioUrl!.isNotEmpty) {
      _player.setUrl(widget.khutbah.audioUrl!);
    }
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';
    final k = widget.khutbah;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        centerTitle: true,
        title: Text(
          'home.stats.archived'.tr(),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.pureWhite : AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section with title and date
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppStyles.elevatedShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.title,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat.yMMMMd().format(k.date),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(k.durationSeconds),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  if (k.imamName != null && k.imamName!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          k.imamName!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Audio Player (if available)
            if (k.audioUrl != null && k.audioUrl!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E20) : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark ? [] : AppStyles.cardShadow,
                  border: isDark ? Border.all(color: AppColors.doveGray.withOpacity(0.1)) : null,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isPlaying) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPlaying ? 'discovery.audioPlaying'.tr() : 'discovery.audioReady'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.pureWhite : AppColors.ink,
                            ),
                          ),
                          Text(
                            'Recorded on ${DateFormat.jm().format(k.date)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.slate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Transcript Section
            Text(
              'home.stats.khutbahsLabel'.tr().toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 16),

            if (k.transcript.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'discovery.noTranscript'.tr(),
                    style: const TextStyle(color: AppColors.slate, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ...k.transcript.map((line) => _TranscriptCard(
                line: line,
              )),
          ],
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final TranscriptLine line;

  const _TranscriptCard({
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E20) : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : AppStyles.cardShadow,
        border: isDark ? Border.all(color: AppColors.doveGray.withOpacity(0.1)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  line.time,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Arabic Original
          if (line.ar.isNotEmpty) ...[
            Text(
              line.ar,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 22,
                height: 1.6,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.pureWhite : AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // English Translation
          if (line.en.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.accentGreen, width: 2)),
              ),
              child: Text(
                line.en,
                textAlign: TextAlign.left,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.slate,
                ),
              ),
            ),
          ] else if (line.ar.isNotEmpty) ...[
            // Fallback message if translation is missing
            Text(
              'Translation not available',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.slate.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
