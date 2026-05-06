import 'dart:async';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/ai/aban_ai_repository.dart';
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
  final _aiRepository = sl<AbanAiRepository>();

  bool _isCapturing = false;
  bool _isStarting = false; // true while the Firestore write is in-flight
  bool _guidelinesAccepted = false;
  bool _isLowVolume = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _chunkTimer;
  double _currentAmplitude = -160.0;
  int _lowVolumeTicks = 0;
  late AnimationController _pulseController;

  final _stopwatch = Stopwatch();
  Timer? _ticker;
  String _elapsed = '00:00:00';

  String _lastArabic = '';
  double _chunkMaxAmplitude = -160.0;

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
    _chunkTimer?.cancel();
    _pulseController.dispose();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
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
      await _startAudioMonitoring();
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

  Future<void> _startAudioMonitoring() async {
    if (await _audioRecorder.hasPermission()) {
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web browsers cannot record .wav files natively. Please test this on an Android or iOS device/emulator, or update your backend to support WebM!'),
            duration: Duration(seconds: 8),
          ),
        );
        return;
      }
      
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
      _chunkMaxAmplitude = -160.0;
      _chunkTimer = Timer.periodic(const Duration(seconds: 8), (_) => _recordNextChunk());
      
      _amplitudeSub = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 200)).listen((amp) {
        if (!mounted) return;
        setState(() {
          _currentAmplitude = amp.current;
          if (_currentAmplitude > _chunkMaxAmplitude) {
            _chunkMaxAmplitude = _currentAmplitude;
          }
          
          // Simple heuristic for low volume: amplitude < -35 dB
          if (_currentAmplitude < -35.0) {
            _lowVolumeTicks++;
          } else {
            _lowVolumeTicks = 0;
            _isLowVolume = false;
          }

          if (_lowVolumeTicks > 10) { // 2 seconds of low volume
            _isLowVolume = true;
          }
        });
      });
    } else {
      if (!mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to broadcast.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _recordNextChunk() async {
    final path = await _audioRecorder.stop();
    
    if (_isCapturing) {
      final dir = await getTemporaryDirectory();
      final newPath = '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: newPath);
    }

    if (path != null) {
      final timeStr = _elapsed;
      final maxAmp = _chunkMaxAmplitude;
      _chunkMaxAmplitude = -160.0; // Reset for next chunk
      _uploadChunk(path, timeStr, maxAmp); // run in background
    }
  }

  Future<void> _uploadChunk(String path, String timeStr, double chunkMaxAmplitude) async {
    try {
      print("Recording chunk... max amplitude: $chunkMaxAmplitude");
      if (chunkMaxAmplitude < -35.0) {
        print("Skipping silent chunk");
        return;
      }

      List<int> bytes;
      String ext = 'wav'; // Now we are forcing WAV format on mobile
      
      if (kIsWeb) {
        final res = await http.get(Uri.parse(path));
        bytes = res.bodyBytes;
      } else {
        bytes = await File(path).readAsBytes();
      }
      
      print("Sending chunk to AI...");
      final result = await _aiRepository.processAudioChunk(bytes, timeStr, ext);
      print("AI RESULT: $result");

      if (result != null && mounted) {
        final ar = result.ar.trim();
        if (ar.isEmpty || ar.length < 4) {
          print("Hallucination skipped (too short)");
          return;
        }

        if (ar == _lastArabic) {
          print("Duplicate skipped");
          return;
        }

        _lastArabic = ar;

        print("Uploading transcript to Firestore...");
        await ref.read(mosqueRepositoryProvider.notifier).appendTranscript(widget.mosqueId, result);
        print("Firestore upload success");
      }
    } catch (e) {
      print("Upload Chunk Error: $e");
    }
  }

  Future<void> _stopCapture() async {
    _pulseController.stop();
    _pulseController.reset();
    _stopTimer();
    _chunkTimer?.cancel();
    _amplitudeSub?.cancel();
    setState(() => _isCapturing = false);
    
    final path = await _audioRecorder.stop();
    if (path != null) {
      await _uploadChunk(path, _elapsed, _chunkMaxAmplitude);
    }

    // Determine current transcript and mosque info before stopping
    final mosqueList = ref.read(mosqueRepositoryProvider).valueOrNull ?? [];
    Mosque? currentMosque;
    for (final m in mosqueList) {
      if (m.id == widget.mosqueId) {
        currentMosque = m;
        break;
      }
    }
    
    final transcript = currentMosque?.transcript ?? [];

    try {
      await ref
          .read(mosqueRepositoryProvider.notifier)
          .stopRecording(widget.mosqueId);
    } catch (_) {
      // Best-effort
    }

    if (transcript.isNotEmpty && mounted) {
      final bool? saveArchive = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Khutbah?'),
          content: const Text(
            "Do you want to save this khutbah to this mosque's archive?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (saveArchive == true) {
        final archive = ArchivedKhutbah(
          id: '',
          title: currentMosque?.topic ?? 'Khutbah',
          date: DateTime.now(),
          transcript: transcript,
          mosqueId: widget.mosqueId,
          imamName: currentMosque?.imamName,
          topic: currentMosque?.topic,
        );
        try {
          await ref
              .read(mosqueRepositoryProvider.notifier)
              .saveArchive(widget.mosqueId, archive);
        } catch (e) {
          debugPrint('Failed to save archive: $e');
        }
      }
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
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
                            if (_isCapturing) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.wifi, color: AppColors.accentGreen, size: 20),
                            ],
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
                                  // Scale pulse by actual amplitude if capturing
                                  final normalizedAmp = _isCapturing ? (_currentAmplitude.clamp(-50.0, 0.0) + 50.0) / 50.0 : 0.0;
                                  final pulseScale = _isCapturing ? (normalizedAmp * 24.0) : (_pulseController.value * 8);

                                  return Container(
                                    padding: EdgeInsets.all(32 + pulseScale),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isCapturing
                                          ? AppColors.error
                                              .withValues(alpha: 0.1 + (normalizedAmp * 0.2))
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
                                      : 'Acknowledge guidelines to start session.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: mutedColor),
                            ),
                            if (_isLowVolume && _isCapturing) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                                    SizedBox(width: 8),
                                    Text('Low volume. Please move closer.', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
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

                      if (_isCapturing && (mosque?.transcript.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Live Transcript Preview',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: mutedColor,
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: subtleSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: (mutedColor ?? Colors.grey).withValues(alpha: 0.2)),
                          ),
                          child: ListView.separated(
                            itemCount: mosque!.transcript.length,
                            separatorBuilder: (_, __) => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1),
                            ),
                            itemBuilder: (context, index) {
                              final line = mosque!.transcript[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    line.ar,
                                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    line.en,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5, 
                                      color: mutedColor,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],

                      const Spacer(),

                      if (!_isCapturing) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: subtleSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Capture Guidelines',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text('• Ensure you are close to the speakers/Khatib.\n• Do not close the app while streaming.\n• Make sure you have a stable internet connection.', style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _guidelinesAccepted,
                                      onChanged: (val) {
                                        setState(() => _guidelinesAccepted = val ?? false);
                                      },
                                      activeColor: AppColors.accentGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'I acknowledge and agree to the guidelines.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_isCapturing)
                        AppButton(
                          label: 'End Capture',
                          icon: Icons.stop,
                          onPressed: () async {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('dialogs.endCapture.title'.tr()),
                                content: Text('dialogs.endCapture.message'.tr()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text('dialogs.endCapture.cancel'.tr()),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: Text(
                                      'dialogs.endCapture.confirm'.tr(),
                                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              _stopCapture();
                            }
                          },
                          variant: AppButtonVariant.error,
                        )
                      else
                        AppButton(
                          label: 'Start Live Capture',
                          icon: Icons.mic,
                          onPressed: (_isStarting || !_guidelinesAccepted) ? null : _startCapture,
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
            );
          },
        ),
      ),
              ),
      ),
    );
  }
}
