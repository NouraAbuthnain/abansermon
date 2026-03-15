import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

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
        left: 20,
        right: 20,
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
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.pureWhite, size: 20),
                ),
              ),
              Row(
                children: [
                  _LivePulseIndicator(),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Friday Khutbah',
            style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Al-Noor Mosque · Sheikh Ahmad',
            style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      margin: const EdgeInsets.only(bottom: 12),
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
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.ink,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Amiri', // Usually better for Arabic if available
            ),
          ),
          const SizedBox(height: 8),
          Text(
            line['en']!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            line['time']!,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.slate.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.4,
                        backgroundColor: AppColors.doveGray.withOpacity(0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentGreen),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('23:45',
                            style: TextStyle(
                                color: AppColors.slate, fontSize: 10)),
                        Text('~45:00',
                            style: TextStyle(
                                color: AppColors.slate, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.volume_up, color: AppColors.slate, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // Implement feedback / end session logic
                context.pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.error.withOpacity(0.1),
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('End Session & Give Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
