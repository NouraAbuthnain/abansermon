import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_back_button.dart';
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

class _LiveKhutbahScreenState extends ConsumerState<LiveKhutbahScreen> {
  bool _isPlaying = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'French',
    'Turkish',
    'Urdu',
    'Malay',
    'Indonesian'
  ];

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

  @override
  Widget build(BuildContext context) {
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
            child: lines.isEmpty
                ? Center(
                    child: Text(
                      'discovery.emptyResults'.tr(),
                      style: const TextStyle(color: AppColors.slate),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
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
          Text(
            line.ar,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Amiri',
                ),
          ),
          const SizedBox(height: 8),
          Text(
            line.en,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            line.time,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.color
                      ?.withValues(alpha: 0.6),
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
                onTap: () => setState(() => _isPlaying = !_isPlaying),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.4,
                        backgroundColor:
                            AppColors.doveGray.withValues(alpha: 0.4),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentGreen),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('23:45',
                            style: Theme.of(context).textTheme.labelLarge),
                        Text('~45:00',
                            style: Theme.of(context).textTheme.labelLarge),
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
