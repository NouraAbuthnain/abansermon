import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/ai/aban_ai_repository.dart';
import '../../mosque_discovery/data/mosque_repository.dart';
import '../../mosque_discovery/domain/mosque.dart';
import '../../feedback/presentation/feedback_bottom_sheet.dart';
import '../../../core/widgets/app_back_button.dart';

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
  bool _isStarting = false;
  bool _isLowVolume = false;
  bool _isErrorState = false;
  final List<TranscriptLine> _transcriptChunks = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  String _statusMessage = 'Listening...';

  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _chunkTimer;
  double _currentAmplitude = -160.0;
  int _lowVolumeTicks = 0;
  late AnimationController _pulseController;

  final _stopwatch = Stopwatch();
  Timer? _ticker;
  Timer? _heartbeatTimer;
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
    _heartbeatTimer?.cancel();
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
    if (recorderId == null) return; 

    setState(() => _isStarting = true);
    try {
      await ref
          .read(mosqueRepositoryProvider.notifier)
          .startRecording(widget.mosqueId, recorderId);

      setState(() {
        _isStarting = false;
        _isCapturing = true;
        _isErrorState = false;
        _statusMessage = 'services.capture.statusListening'.tr();
        _transcriptChunks.clear();
        _lastArabic = '';
      });
      debugPrint("Capture: Recording started for mosque ${widget.mosqueId}");
      _pulseController.repeat(reverse: true);
      _startTimer();
      _startHeartbeat();
      await _startAudioMonitoring();
    } catch (e) {
      debugPrint("Capture: Failed to start recording: $e");
      if (!mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _isCapturing) {
        ref.read(mosqueRepositoryProvider.notifier).updateHeartbeat(widget.mosqueId);
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _startAudioMonitoring() async {
    final hasPermission = await _audioRecorder.hasPermission();
    debugPrint("Capture: Microphone permission granted: $hasPermission");
    if (hasPermission) {
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web browsers cannot record .wav files natively. Please test on a mobile device.'),
            duration: Duration(seconds: 5),
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
      debugPrint("Capture: Recording chunk... max amplitude: $chunkMaxAmplitude");
      if (chunkMaxAmplitude < -35.0) {
        debugPrint("Capture: Skipping silent chunk");
        return;
      }

      List<int> bytes;
      const String ext = 'wav';

      if (kIsWeb) {
        final res = await http.get(Uri.parse(path));
        bytes = res.bodyBytes;
      } else {
        bytes = await File(path).readAsBytes();
      }

      debugPrint("Capture: Sending chunk to AI... (${bytes.length} bytes)");
      final result = await _aiRepository.processAudioChunk(bytes, timeStr, ext);
      debugPrint("Capture: AI result: $result");

      if (result != null && mounted) {
        final ar = result.ar.trim();
        if (ar.isEmpty || ar.length < 4) {
          debugPrint("Capture: Hallucination skipped (too short)");
          return;
        }
        if (ar == _lastArabic) {
          debugPrint("Capture: Duplicate skipped");
          return;
        }
        _lastArabic = ar;

        final newChunk = TranscriptLine(ar: ar, en: result.en.trim(), time: timeStr);
        setState(() {
          _isErrorState = false;
          _transcriptChunks.insert(0, newChunk);
        });
        _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));

        debugPrint("Capture: Uploading transcript to Firestore...");
        await ref.read(mosqueRepositoryProvider.notifier).appendTranscript(widget.mosqueId, newChunk);
        debugPrint("Capture: Firestore upload success");
      }
    } catch (e) {
      debugPrint("Capture: Upload chunk error: $e");
    }
  }

  Future<void> _stopCapture() async {
    _pulseController.stop();
    _pulseController.reset();
    _stopTimer();
    _chunkTimer?.cancel();
    _amplitudeSub?.cancel();
    _stopHeartbeat();
    setState(() => _isCapturing = false);

    // Flush the final in-progress chunk before stopping — same as APK behaviour
    final path = await _audioRecorder.stop();
    if (path != null) {
      await _uploadChunk(path, _elapsed, _chunkMaxAmplitude);
    }

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
      await ref.read(mosqueRepositoryProvider.notifier).stopRecording(widget.mosqueId);
    } catch (_) {}

    if (transcript.isNotEmpty && mounted) {
      final bool? saveArchive = await AppDialog.show<bool>(
        context,
        barrierDismissible: false,
        type: AppDialogType.confirmation,
        title: 'services.capture.saveArchiveTitle'.tr(),
        message: 'services.capture.saveArchiveMessage'.tr(),
        primaryLabel: 'services.capture.saveArchiveYes'.tr(),
        secondaryLabel: 'services.capture.saveArchiveNo'.tr(),
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
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
          await ref.read(mosqueRepositoryProvider.notifier).saveArchive(widget.mosqueId, archive);
        } catch (e) {
          debugPrint('Failed to save archive: $e');
        }
      }
    }

    if (mounted) {
      final String khutbahId = 'capture_${widget.mosqueId}_${DateTime.now().millisecondsSinceEpoch}';
      await FeedbackBottomSheet.show(context, khutbahId);
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return PopScope(
      canPop: !_isCapturing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isCapturing) {
          // Could show a toast or just stay put
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: Text(
            'services.capture.title'.tr(),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? AppColors.pureWhite : AppColors.primaryTeal,
            ),
          ),
          leading: AppBackButton(
            onPressed: _isCapturing ? null : () => context.pop(),
          ),
          actions: [
            if (_isCapturing)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Reset Microphone',
                onPressed: () async {
                  debugPrint("Capture: Manually resetting microphone stream...");
                  await _audioRecorder.stop();
                  await _startAudioMonitoring();
                },
              ),
          ],
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isCapturing ? _buildRecordingState() : _buildIdleState(),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.doveGray : AppColors.slate;

    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
                boxShadow: isDark ? [] : AppStyles.elevatedShadow,
              ),
              child: Image.asset(
                'assets/icons/microphone.png',
                width: 80,
                height: 80,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'services.capture.ready'.tr(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: isDark ? AppColors.pureWhite : AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'services.capture.idleSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: mutedColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      key: const ValueKey('recording'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Row(
            children: [
              _buildLiveIndicator(),
              const SizedBox(width: 12),
              Text(
                'services.capture.recordingLive'.tr(),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.pureWhite : AppColors.primaryTeal,
                ),
              ),
              const Spacer(),
              Text(
                _elapsed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isDark ? AppColors.pureWhite : AppColors.primaryTeal,
                ),
              ),
            ],
          ),
        ),
        if (_isLowVolume)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentAmplitude <= -100.0 ? Icons.mic_off_rounded : Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentAmplitude <= -100.0 
                        ? 'services.capture.noSound'.tr() 
                        : 'services.capture.lowVolume'.tr(args: [_currentAmplitude.toStringAsFixed(1)]),
                    style: GoogleFonts.cairo(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: _transcriptChunks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _isErrorState ? AppColors.error : AppColors.slate,
                          fontWeight: _isErrorState ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                )
              : AnimatedList(
                  key: _listKey,
                  initialItemCount: _transcriptChunks.length,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  itemBuilder: (context, index, animation) {
                    return _buildTranscriptCard(_transcriptChunks[index], animation);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTranscriptCard(TranscriptLine chunk, Animation<double> animation) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : AppStyles.cardShadow,
            border: isDark ? Border.all(color: AppColors.doveGray.withOpacity(0.1)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.accentGreen : AppColors.primaryTeal).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chunk.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const Icon(Icons.auto_awesome, size: 14, color: AppColors.doveGray),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                chunk.ar,
                textAlign: TextAlign.center,
                textDirection: ui.TextDirection.rtl,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 32,
                  height: 1.8,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isDark ? AppColors.pureWhite : AppColors.ink,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: AppColors.doveGray, thickness: 0.5),
              ),
              Text(
                chunk.en,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.doveGray : AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.4 * _pulseController.value),
                blurRadius: 8 * _pulseController.value,
                spreadRadius: 4 * _pulseController.value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, (bottomInset > 0 ? bottomInset : 24)),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: AppColors.doveGray.withOpacity(0.2)),
        ),
      ),
      child: _isCapturing
          ? AppButton(
              label: 'Stop Recording',
              icon: Icons.stop_rounded,
              variant: AppButtonVariant.error,
              onPressed: _isStarting ? null : () async {
                final bool? confirm = await AppDialog.show<bool>(
                  context,
                  type: AppDialogType.warning,
                  title: 'services.capture.endSessionTitle'.tr(),
                  message: 'services.capture.endSessionMessage'.tr(),
                  primaryLabel: 'services.capture.endSessionConfirm'.tr(),
                  secondaryLabel: 'services.capture.endSessionCancel'.tr(),
                  isDestructive: true,
                  onPrimaryPressed: () => Navigator.of(context).pop(true),
                  onSecondaryPressed: () => Navigator.of(context).pop(false),
                );
                if (confirm == true) _stopCapture();
              },
            )
          : AppButton(
              label: 'services.capture.startRecording'.tr(),
              icon: Icons.mic_rounded,
              onPressed: _isStarting ? null : _startCapture,
              variant: AppButtonVariant.primary,
            ),
    );
  }
}

