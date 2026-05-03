import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/di/injection_container.dart';
import '../../../domain/interfaces/ai_interfaces.dart';
import '../../mosque_discovery/data/mosque_repository.dart';
import '../../mosque_discovery/domain/mosque.dart';

class LiveKhutbahScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const LiveKhutbahScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<LiveKhutbahScreen> createState() => _LiveKhutbahScreenState();
}

class _LiveKhutbahScreenState extends ConsumerState<LiveKhutbahScreen> with TickerProviderStateMixin {
  bool _isPlaying = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _audioProgressController;
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'French',
    'Turkish',
    'Urdu',
    'Malay',
    'Indonesian'
  ];
  
  final _ttsService = sl<ITextToSpeechService>();
  int _lastSpokenIndex = -1;

  @override
  void initState() {
    super.initState();
    _audioProgressController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 45), // Mock Khutbah duration
    );
    if (_isPlaying) {
      _audioProgressController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioProgressController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  /// Session ids look like `mock_session_<mosqueId>`. In the dummy phase we
  /// derive the mosque from the suffix; in production a session entity will
  /// own its own mosque reference.
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

  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    // Initialise the index so we don't speak old messages when joining late.
    if (_isFirstLoad) {
      final m = _resolveMosque();
      if (m != null) {
        _lastSpokenIndex = m.transcript.length - 1;
        _isFirstLoad = false;
      }
    }

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
          print("Guest received transcript update");
          print("TTS speaking line: ${lines[_lastSpokenIndex].en}");
          _ttsService.speak(lines[_lastSpokenIndex].en, 'en');
        }
      }
    });

    final mosque = _resolveMosque();
    final lines = mosque?.transcript ?? const [];

    return Scaffold(
      // Inherits scaffoldBackgroundColor from the active theme — cloud in
      // light mode, ink in dark mode.
      body: Column(
        children: [
          _buildHeader(context, mosque),
          _buildLanguageSelector(context),
          Expanded(
            child: (mosque == null || !mosque.isLive)
                ? _buildEmptyState(context, isOffline: true)
                : lines.isEmpty
                    ? _buildEmptyState(context, isOffline: false)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          // Auto-scroll when new items are added
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
                      ),
          ),
          _buildAudioControls(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Mosque? mosque) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppBackButton(),
              Row(
                children: [
                  _LivePulseIndicator(),
                  const SizedBox(width: 8),
                  Text(
                    'khutbah.live'.tr(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mosque?.topic ?? 'khutbah.title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.pureWhite,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDetails(mosque),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  String _formatDetails(Mosque? mosque) {
    if (mosque == null) return 'khutbah.title'.tr();
    final imam = mosque.imamName ?? '';
    return '${mosque.name} · $imam'.trim();
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.language, size: 16, color: AppColors.accentGreen),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.slate),
              dropdownColor: Theme.of(context).cardTheme.color,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedLanguage = newValue);
                }
              },
              items: _languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isOffline}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.cell_tower : Icons.mic_off,
              size: 64,
              color: AppColors.doveGray,
            ),
            const SizedBox(height: 16),
            Text(
              isOffline 
                  ? 'No live Khutbah is currently available for this mosque.' 
                  : 'Waiting for the Khatib to begin speaking...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.slate,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptBubble(
      BuildContext context, TranscriptLine line, bool isLatest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
        border: isLatest
            ? Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                line.time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.slate,
                    ),
              ),
              if (isLatest)
                const Icon(Icons.volume_up, size: 16, color: AppColors.accentGreen)
            ],
          ),
          const SizedBox(height: 12),
          Text(
            line.ar,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Amiri',
                ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.doveGray, height: 1),
          ),
          Text(
            line.en,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.greenMist 
                      : AppColors.primaryTeal,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: AppStyles.elevatedShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _isPlaying = !_isPlaying);
                  if (_isPlaying) {
                    _audioProgressController.forward();
                  } else {
                    _audioProgressController.stop();
                  }
                },
                customBorder: const CircleBorder(),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                    boxShadow: AppStyles.elevatedShadow,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _audioProgressController,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _audioProgressController.value,
                            backgroundColor:
                                AppColors.doveGray.withValues(alpha: 0.4),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accentGreen),
                            minHeight: 8,
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedBuilder(
                          animation: _audioProgressController,
                          builder: (context, child) {
                            final elapsed = _audioProgressController.duration! * _audioProgressController.value;
                            return Text('${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.labelLarge);
                          }
                        ),
                        Text('Live',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.volume_up, color: AppColors.slate, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'khutbah.endSession'.tr(),
            onPressed: () => context.pop(),
            variant: AppButtonVariant.error,
          ),
        ],
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
