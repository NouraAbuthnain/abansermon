import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme.dart';

class LiveKhutbahCard extends StatelessWidget {
  const LiveKhutbahCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Background svg circles simulation (geometric pattern)
          Positioned(
            right: -24,
            top: -24,
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                size: const Size(100, 100),
                painter: _GeometricPainter(),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Badge
              Row(
                children: [
                  _LivePulseIndicator(),
                  const SizedBox(width: 8),
                  Text(
                    'home.stats.liveNow'.tr(),
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info
              Text(
                'khutbah.title'.tr(),
                style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'khutbah.details'.tr(args: ['Al-Noor', 'Ahmad']),
                style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.8), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'home.topicLabel'.tr(args: ['Patience in Times of Trial']),
                style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Transcript preview (Glassmorphism)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"...and indeed, Allah is with the patient. We must remember that every hardship carries..."',
                  style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Audio Controls
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pause,
                        color: AppColors.pureWhite, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: AppColors.pureWhite.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentGreen),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.volume_up,
                      color: AppColors.pureWhite.withOpacity(0.6), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '23:45',
                    style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.6),
                        fontSize: 12),
                  ),
                ],
              ),
            ],
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

class _GeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 48, paint);
    canvas.drawCircle(center, 35, paint);
    canvas.drawCircle(center, 22, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
