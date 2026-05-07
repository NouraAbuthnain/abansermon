import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_language_button.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/di/injection_container.dart';
import '../../../domain/interfaces/ai_interfaces.dart';
import '../../mosque_discovery/data/mosque_repository.dart';
import '../../mosque_discovery/domain/mosque.dart';
import '../../feedback/presentation/feedback_bottom_sheet.dart';

class LiveKhutbahScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const LiveKhutbahScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<LiveKhutbahScreen> createState() => _LiveKhutbahScreenState();
}

class _LiveKhutbahScreenState extends ConsumerState<LiveKhutbahScreen> {
  final ScrollController _scrollController = ScrollController();
  
  final _ttsService = sl<ITextToSpeechService>();
  int _lastSpokenIndex = -1;
  bool _isMuted = false;
  double _volume = 0.7;

  @override
  void initState() {
    super.initState();
    _ttsService.setVolume(_volume);
    _ttsService.setMuted(_isMuted);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  String? get _mosqueIdFromSession {
    const prefix = 'mock_session_';
    if (widget.sessionId.startsWith(prefix)) {
      return widget.sessionId.substring(prefix.length);
    }
    return null;
  }

  Mosque? _resolveMosque() {
    final mosqueId = _mosqueIdFromSession;
    if (mosqueId == null) return null;
    final list = ref.watch(mosqueRepositoryProvider).valueOrNull ?? [];
    for (final m in list) {
      if (m.id == mosqueId) return m;
    }
    return null;
  }

  Future<void> _handleExit() async {
    final mosque = _resolveMosque();
    final khutbahId = mosque?.id ?? widget.sessionId;

    final result = await AppBottomSheet.show<String>(
      context,
      title: 'Leave Sermon?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your feedback helps us improve translation quality for everyone.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Submit Feedback',
            onPressed: () => Navigator.pop(context, 'feedback'),
            variant: AppButtonVariant.primary,
            icon: Icons.rate_review_rounded,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Leave Sermon',
            onPressed: () => Navigator.pop(context, 'leave'),
            variant: AppButtonVariant.tertiary,
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'feedback') {
      final submitted = await FeedbackBottomSheet.show(context, khutbahId);
      if (submitted == true && mounted) {
        context.pop(); // Close screen after feedback
      }
    } else if (result == 'leave') {
      context.pop();
    }
  }

  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Initialize spoken index
    if (_isFirstLoad) {
      final m = _resolveMosque();
      if (m != null) {
        _lastSpokenIndex = m.transcript.length - 1;
        _isFirstLoad = false;
      }
    }

    // Listen for new transcript updates
    ref.listen(mosqueRepositoryProvider, (previous, next) {
      final list = next.valueOrNull ?? [];
      Mosque? m;
      for (final doc in list) {
        if (doc.id == _mosqueIdFromSession) {
          m = doc;
          break;
        }
      }
      
      if (m != null) {
        final lines = m.transcript;
        if (lines.isNotEmpty && lines.length - 1 > _lastSpokenIndex) {
          _lastSpokenIndex = lines.length - 1;
          if (!_isMuted) {
            // Speak the translated text if available (en), else Arabic (ar)
            final languageCode = context.locale.languageCode;
            final textToSpeak = languageCode == 'en' 
                ? lines[_lastSpokenIndex].en 
                : lines[_lastSpokenIndex].ar;
            final code = languageCode == 'en' ? 'en' : 'ar';
            _ttsService.speak(textToSpeak, code);
          }
        }
      }
    });

    final mosque = _resolveMosque();
    final lines = mosque?.transcript ?? const [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Live Translation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.pureWhite : AppColors.primaryTeal,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _handleExit,
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            _buildTopLanguageSection(context),
            Expanded(
              child: (mosque == null || !mosque.isLive || lines.isEmpty)
                  ? _buildEmptyState(context)
                  : _buildTranscriptList(lines),
            ),
            _buildBottomAudioPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopLanguageSection(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: AppLanguageButton(),
      ),
    );
  }

  Widget _buildTranscriptList(List<TranscriptLine> lines) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        // Auto-scroll logic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        final line = lines[index];
        final isLatest = index == lines.length - 1;
        return _buildTranscriptBubble(context, line, isLatest);
      },
    );
  }

  Widget _buildTranscriptBubble(BuildContext context, TranscriptLine line, bool isLatest) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line.ar.isNotEmpty)
            Text(
              line.ar,
              textAlign: TextAlign.right,
              style: TextStyle(
                height: 1.8,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                color: isLatest 
                  ? (isDark ? AppColors.pureWhite : AppColors.ink)
                  : AppColors.slate,
              ),
            ),
          if (line.ar.isNotEmpty && line.en.isNotEmpty)
            const SizedBox(height: 12),
          if (line.en.isNotEmpty)
            Text(
              line.en,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 18,
                color: isLatest
                  ? AppColors.primaryTeal
                  : AppColors.slate.withOpacity(0.7),
                fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          if (isLatest)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomAudioPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, (bottomInset > 0 ? bottomInset + 16 : 24)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
        boxShadow: AppStyles.elevatedShadow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCompactVolumeButton(
                icon: Icons.volume_down_rounded,
                onPressed: () {
                  setState(() {
                    _volume = (_volume - 0.1).clamp(0.0, 1.0);
                    _ttsService.setVolume(_volume);
                  });
                },
              ),
              const SizedBox(width: 40),
              _buildCompactVolumeButton(
                icon: Icons.volume_up_rounded,
                onPressed: () {
                  setState(() {
                    _volume = (_volume + 0.1).clamp(0.0, 1.0);
                    _ttsService.setVolume(_volume);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _isMuted ? 'Unmute Translation Audio' : 'Mute Translation Audio',
            onPressed: () {
              setState(() => _isMuted = !_isMuted);
              _ttsService.setMuted(_isMuted);
            },
            variant: _isMuted ? AppButtonVariant.primary : AppButtonVariant.secondary,
            icon: _isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVolumeButton({required IconData icon, required VoidCallback onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.slate.withOpacity(0.1) : AppColors.cloud,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primaryTeal, size: 24),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.translate_rounded,
                size: 48,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No live sermon is currently available',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LivePulseIndicator extends StatefulWidget {
  @override
  State<_LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<_LivePulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 10 + (_controller.value * 6),
              height: 10 + (_controller.value * 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen
                    .withValues(alpha: 0.4 - (_controller.value * 0.3)),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen,
              ),
            ),
          ],
        );
      },
    );
  }
}
