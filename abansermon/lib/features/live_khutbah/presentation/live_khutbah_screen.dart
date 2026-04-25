import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_back_button.dart';

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

  // Mock transcript
  final List<Map<String, String>> _transcriptLines = [
    {
      "ar": "بسم الله الرحمن الرحيم",
      "en": "In the name of Allah, the Most Gracious, the Most Merciful",
      "time": "0:00"
    },
    {
      "ar": "الحمد لله رب العالمين",
      "en": "All praise is due to Allah, Lord of all worlds",
      "time": "0:12"
    },
    {
      "ar": "موضوع خطبتنا اليوم هو الصبر",
      "en": "The topic of our sermon today is patience",
      "time": "0:30"
    },
    {
      "ar": "إن الله مع الصابرين",
      "en": "Indeed, Allah is with the patient",
      "time": "0:45"
    },
    {
      "ar": "وكل ابتلاء يحمل في طياته بركة",
      "en": "And every hardship carries within it a blessing",
      "time": "1:02"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: Column(
        children: [
          _buildHeader(context),
          _buildLanguageSelector(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _transcriptLines.length,
              itemBuilder: (context, index) {
                final line = _transcriptLines[index];
                bool isLatest = index == _transcriptLines.length - 1;
                return _buildTranscriptBubble(line, isLatest);
              },
            ),
          ),
          _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'khutbah.title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.pureWhite,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'khutbah.details'.tr(args: ['Al-Noor', 'Ahmad']),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.pureWhite.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
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

  Widget _buildTranscriptBubble(Map<String, String> line, bool isLatest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
        border: isLatest
            ? Border.all(
                color: AppColors.accentGreen.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            line['ar']!,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Amiri',
                ),
          ),
          const SizedBox(height: 8),
          Text(
            line['en']!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            line['time']!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.slate.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border:
            Border(top: BorderSide(color: AppColors.doveGray.withOpacity(0.2))),
        boxShadow: AppStyles.elevatedShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isPlaying = !_isPlaying),
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
                        backgroundColor: AppColors.doveGray.withOpacity(0.5),
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
                    .withOpacity(0.4 - (_controller.value * 0.3)),
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
