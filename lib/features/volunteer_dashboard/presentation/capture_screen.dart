import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/interfaces/ai_interfaces.dart';
import '../../mosque_discovery/data/mosque_repository.dart';
import '../../mosque_discovery/domain/mosque.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String mosqueId;
  const CaptureScreen({super.key, required this.mosqueId});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with SingleTickerProviderStateMixin {
  final _asrService = sl<IAudioTranscriptionService>();

  bool _isCapturing = false;
  bool _isStarting = false; // true while the Firestore write is in-flight
  late AnimationController _pulseController;

  final _stopwatch = Stopwatch();
  Timer? _ticker;
  String _elapsed = '00:00:00';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    _asrService.dispose();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = _formatElapsed(_stopwatch.elapsed));
      }
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _elapsed = '00:00:00';
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _startCapture() async {
    final recorderId = ref.read(authProvider).userId;
    if (recorderId == null) return; // ActionGuard already blocks this path

    setState(() => _isStarting = true);
    try {
      await ref
          .read(mosqueRepositoryProvider.notifier)
          .startRecording(widget.mosqueId, recorderId);

      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _isCapturing = true;
      });
      _pulseController.repeat(reverse: true);
      _startTimer();
      _asrService.startCapture(); // phase-2: ASR pipeline — kept as-is
    } catch (_) {
      if (!mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start recording. Check your connection.'),
        ),
      );
    }
  }

  Future<void> _stopCapture() async {
    _pulseController.stop();
    _pulseController.reset();
    _stopTimer();
    setState(() => _isCapturing = false);

    _asrService.stopCapture(); // phase-2: ASR pipeline — kept as-is

    try {
      await ref
          .read(mosqueRepositoryProvider.notifier)
          .stopRecording(widget.mosqueId);
    } catch (_) {
      // Best-effort: if the write fails the mosque stays "active" until an
      // admin resets it (decision 1-C). We still navigate away.
    }

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final mutedColor = theme.textTheme.bodyMedium?.color;
    final isDark = theme.brightness == Brightness.dark;
    final subtleSurface =
        isDark ? AppColors.ink.withValues(alpha: 0.4) : AppColors.cloud;

    // Resolved mosque from the live stream — used for name display.
    final mosqueList = ref.watch(mosqueRepositoryProvider).valueOrNull ?? [];
    Mosque? mosque;
    for (final m in mosqueList) {
      if (m.id == widget.mosqueId) {
        mosque = m;
        break;
      }
    }
    final mosqueName = mosque?.name ?? widget.mosqueId;

    return PopScope(
      // Prevent back gesture/button while recording is active.
      canPop: !_isCapturing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Capture Control',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              // Disable close while recording — user must press "End Capture".
              onPressed: _isCapturing ? null : () => context.go('/home'),
            ),
          ],
        ),
        body: widget.mosqueId.isEmpty
            ? const Center(child: Text('Error: No Mosque Context Provided'))
            : SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mosque Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppStyles.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: subtleSurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.mosque,
                                  color: AppColors.primaryTeal),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mosqueName,
                                      style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isCapturing ? 'البث المباشر نشط' : 'جاهز للبث',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _isCapturing
                                          ? AppColors.error
                                          : mutedColor,
                                    ),
                                  ),
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
                          color: cardColor,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: _isCapturing
                              ? [
                                  BoxShadow(
                                      color:
                                          AppColors.error.withValues(alpha: 0.2),
                                      blurRadius: 24,
                                      spreadRadius: 4)
                                ]
                              : AppStyles.elevatedShadow,
                          border: Border.all(
                            color: _isCapturing
                                ? AppColors.error.withValues(alpha: 0.5)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_isStarting)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              )
                            else
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return Container(
                                    padding: EdgeInsets.all(
                                        32 + (_pulseController.value * 8)),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isCapturing
                                          ? AppColors.error
                                              .withValues(alpha: 0.1)
                                          : subtleSurface,
                                    ),
                                    child: Icon(
                                      _isCapturing
                                          ? Icons.mic
                                          : Icons.mic_none,
                                      size: 64,
                                      color: _isCapturing
                                          ? AppColors.error
                                          : AppColors.primaryTeal,
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 24),
                            Text(
                              _isStarting
                                  ? 'CONNECTING...'
                                  : _isCapturing
                                      ? 'LIVE RECORDING'
                                      : 'READY TO STREAM',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: _isCapturing ? AppColors.error : null,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isStarting
                                  ? 'Setting up live stream...'
                                  : _isCapturing
                                      ? 'Streaming live. Keep device near audio source.'
                                      : 'Press button below to start session.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: mutedColor),
                            ),
                            if (_isCapturing) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _elapsed,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Spacer(),

                      if (_isCapturing)
                        AppButton(
                          label: 'End Capture',
                          icon: Icons.stop,
                          onPressed: _stopCapture,
                          variant: AppButtonVariant.error,
                        )
                      else
                        AppButton(
                          label: 'Start Live Capture',
                          icon: Icons.mic,
                          onPressed: _isStarting ? null : _startCapture,
                          variant: AppButtonVariant.primary,
                        ),

                      const SizedBox(height: 24),
                      Text(
                        'By starting capture, you confirm adherence to broadcast regulations and respect for the Khutbah.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: mutedColor),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
