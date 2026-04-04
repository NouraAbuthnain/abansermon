import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/di/injection_container.dart';
import '../../../domain/interfaces/ai_interfaces.dart';

class ManageCaptureScreen extends StatefulWidget {
  const ManageCaptureScreen({super.key});

  @override
  State<ManageCaptureScreen> createState() => _ManageCaptureScreenState();
}

class _ManageCaptureScreenState extends State<ManageCaptureScreen>
    with SingleTickerProviderStateMixin {
  final asrService = sl<IAudioTranscriptionService>();
  bool isCapturing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  void toggleCapture() {
    setState(() {
      isCapturing = !isCapturing;
      if (isCapturing) {
        _pulseController.repeat(reverse: true);
        asrService.startCapture();
      } else {
        _pulseController.stop();
        _pulseController.reset();
        asrService.stopCapture();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    asrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.ink),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mosque Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mosque,
                          color: AppColors.primaryTeal),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Al-Rajhi Grand Mosque',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('ID: mosque_456 · Riyadh',
                              style: TextStyle(
                                  color: AppColors.slate, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Status Panel
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: isCapturing
                      ? [
                          BoxShadow(
                              color: AppColors.error.withOpacity(0.2),
                              blurRadius: 24,
                              spreadRadius: 4)
                        ]
                      : AppStyles.elevatedShadow,
                  border: Border.all(
                    color: isCapturing
                        ? AppColors.error.withOpacity(0.5)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding:
                              EdgeInsets.all(32 + (_pulseController.value * 8)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCapturing
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.cloud,
                          ),
                          child: Icon(
                            isCapturing ? Icons.mic : Icons.mic_none,
                            size: 64,
                            color: isCapturing
                                ? AppColors.error
                                : AppColors.primaryTeal,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isCapturing ? 'LIVE RECORDING' : 'READY TO STREAM',
                      style: TextStyle(
                        color: isCapturing ? AppColors.error : AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCapturing
                          ? 'Streaming live audio to translation service. Keep device near audio source.'
                          : 'Press button below to start session.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: AppColors.slate, fontSize: 14),
                    ),
                    if (isCapturing) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.error, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text('00:15:32',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                        ],
                      ),
                    ]
                  ],
                ),
              ),

              const Spacer(),

              // Action Button — dynamic color (live/stop), custom AppButton-style
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: toggleCapture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCapturing ? AppColors.error : AppColors.accentGreen,
                    foregroundColor: AppColors.pureWhite,
                    elevation: 2,
                    shadowColor: (isCapturing ? AppColors.error : AppColors.accentGreen)
                        .withValues(alpha: 0.4),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isCapturing
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded),
                      const SizedBox(width: 8),
                      Text(
                        isCapturing ? 'END CAPTURE' : 'START LIVE CAPTURE',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'By starting capture, you confirm adherence to broadcast regulations and respect for the Khutbah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate, fontSize: 11),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
