import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/audio_utils.dart';

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
  String _fullTranscriptAr = ''; // Accumulated transcript for deduplication
  String _fullTranscriptEn = '';
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
  final ScrollController _scrollController = ScrollController();
  Timer? _ticker;
  Timer? _heartbeatTimer;
  String _elapsed = '00:00:00';

  String _lastArabic = '';
  double _chunkMaxAmplitude = -160.0;
  final List<int> _audioBuffer = [];
  StreamSubscription<Uint8List>? _streamSub;
  static const int _sampleRate = 16000;
  static const int _bytesPerSecond = _sampleRate * 2; // 16-bit
  static const int _chunkSize = 8 * _bytesPerSecond;
  static const int _overlapSize = 1 * _bytesPerSecond;

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
    _streamSub?.cancel();
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
        _fullTranscriptAr = '';
        _fullTranscriptEn = '';
        _transcriptChunks.clear();
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
      
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        bitRate: 256000,
      );

      final stream = await _audioRecorder.startStream(config);
      
      _audioBuffer.clear();
      _chunkMaxAmplitude = -160.0;

      _streamSub = stream.listen((data) {
        _audioBuffer.addAll(data);
        // Keep buffer manageable: 12 seconds max (gives enough headroom for 8s chunks + processing time)
        const maxKeep = 12 * _bytesPerSecond;
        if (_audioBuffer.length > maxKeep) {
          _audioBuffer.removeRange(0, _audioBuffer.length - maxKeep);
        }
      });

      debugPrint("Capture: Audio monitoring active.");
      debugPrint("Capture: Config - Rate: $_sampleRate Hz, Channels: 1, Format: PCM16");
      debugPrint("Capture: Expected Bytes/Sec: $_bytesPerSecond");
      debugPrint("Capture: Chunk Window: 8s (${_chunkSize} bytes)");
      debugPrint("Capture: Interval: 7s");
      
      _chunkTimer = Timer.periodic(const Duration(seconds: 7), (_) => _processStreamChunk());
      
      _amplitudeSub = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 200)).listen((amp) {
        if (!mounted) return;
        setState(() {
          _currentAmplitude = amp.current;
          if (_currentAmplitude > _chunkMaxAmplitude) {
            _chunkMaxAmplitude = _currentAmplitude;
          }
          
          // Adaptive low volume warning: Only show if consistently low for ~2 seconds
          if (_currentAmplitude < -40.0) {
            _lowVolumeTicks++;
          } else {
            _lowVolumeTicks = 0;
            _isLowVolume = false;
          }

          if (_lowVolumeTicks > 10) { 
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

  Future<void> _processStreamChunk() async {
    final minSafeSize = (7.5 * _bytesPerSecond).toInt();
    final actualBytes = _audioBuffer.length;
    final expectedWindowBytes = _chunkSize;
    
    if (actualBytes < minSafeSize) {
      debugPrint("Capture: Buffer filling... ($actualBytes / $minSafeSize bytes needed for 7.5s)");
      return;
    }

    final takeSize = min(actualBytes, expectedWindowBytes);
    final List<int> chunkBytes = _audioBuffer.sublist(actualBytes - takeSize);
    
    debugPrint("Capture: Chunk processing - Actual: $actualBytes, Taken: $takeSize, Target: $expectedWindowBytes");

    final wavBytes = await compute(_addWavHeaderInBackground, {
      'bytes': chunkBytes,
      'rate': _sampleRate,
    });
    
    final timeStr = _elapsed;
    final maxAmp = _chunkMaxAmplitude;
    _chunkMaxAmplitude = -160.0;
    
    debugPrint("Capture: Audio chunk created at $timeStr. Size: ${wavBytes.length} bytes. Max Amp: ${maxAmp.toStringAsFixed(1)} dB");
    
    // Step 3: Save one chunk locally for debugging (Android/iOS only)
    if (!kIsWeb) {
      try {
        final tempDir = await getTemporaryDirectory();
        final debugFile = File('${tempDir.path}/debug_chunk.wav');
        await debugFile.writeAsBytes(wavBytes);
        debugPrint("Capture Debug: Chunk saved to ${debugFile.path}. Pull this file to verify audio quality.");
      } catch (e) {
        debugPrint("Capture Debug: Failed to save chunk: $e");
      }
    }

    _uploadChunk(wavBytes, timeStr, maxAmp);
  }

  // Top-level or static helper for compute
  static Uint8List _addWavHeaderInBackground(Map<String, dynamic> params) {
    return AudioUtils.addWavHeader(params['bytes'] as List<int>, params['rate'] as int);
  }

  Future<void> _uploadChunk(List<int> bytes, String timeStr, double chunkMaxAmplitude) async {
    try {
      // Diagnostic: Count non-zero/non-silent bytes
      int nonZeroCount = 0;
      for (int i = 0; i < bytes.length; i++) {
        if (bytes[i] != 0 && bytes[i] != 128) {
          nonZeroCount++;
        }
      }
      
      final noiseRatio = (nonZeroCount / bytes.length) * 100;
      debugPrint("Capture Diagnostic: Non-zero data ratio: ${noiseRatio.toStringAsFixed(2)}% (${nonZeroCount} bytes)");

      if (noiseRatio < 0.1 && bytes.isNotEmpty) {
        debugPrint("Capture Warning: Chunk is almost entirely zeros! Microphone is likely dead or muted.");
      }

      // Silence detection: -65dB threshold
      if (chunkMaxAmplitude < -65.0) {
        debugPrint("Capture: Chunk ignored (silence detected: ${chunkMaxAmplitude.toStringAsFixed(1)} dB < -65 dB)");
        return;
      }

      debugPrint("Capture: [REQUEST] ASR/NMT start | Time: $timeStr | Bytes: ${bytes.length} | Amp: ${chunkMaxAmplitude.toStringAsFixed(1)} dB");
      final startTime = DateTime.now();
      
      setState(() {
        _isErrorState = false;
        if (_fullTranscriptAr.isEmpty) _statusMessage = 'services.capture.statusProcessing'.tr();
      });

      String ext = 'wav';
      final result = await _aiRepository.processAudioChunk(bytes, timeStr, ext);
      final latency = DateTime.now().difference(startTime).inMilliseconds;

      if (result != null && mounted) {
        debugPrint("Capture: [RESPONSE] Success | Latency: ${latency}ms | Ar: ${result.ar.length} chars");
        final ar = result.ar.trim();
        final en = result.en.trim();
        
        if (ar.isEmpty) {
          debugPrint("Capture: Ignored empty transcription from AI");
          return;
        }

        final mergedAr = _mergeOverlappingStrings(_fullTranscriptAr, ar);
        final mergedEn = _mergeOverlappingStrings(_fullTranscriptEn, en);
        
        final newAr = mergedAr.substring(_fullTranscriptAr.length).trim();
        final newEn = mergedEn.substring(_fullTranscriptEn.length).trim();

        if (newAr.isEmpty) {
          debugPrint("Capture: No new content after merging");
          return;
        }

        // Hallucination Guard: If audio was silent but AI returned text, it's a hallucination
        if (chunkMaxAmplitude < -65.0 && newAr.length < 10) {
          debugPrint("Capture Warning: AI returned text for silent audio ($chunkMaxAmplitude dB). Ignoring potential hallucination: '$newAr'");
          return;
        }

        final newChunk = TranscriptLine(ar: newAr, en: newEn, time: timeStr);

        setState(() {
          _fullTranscriptAr = mergedAr;
          _fullTranscriptEn = mergedEn;
          _isErrorState = false;
          
          // Add to our list for the UI
          _transcriptChunks.insert(0, newChunk);
        });
        
        // Notify the AnimatedList
        _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));

        debugPrint("Capture: Pushing new transcript to session document");
        await ref.read(mosqueRepositoryProvider.notifier).appendTranscript(widget.mosqueId, newChunk);
        
        // No need for manual scroll if we are inserting at top
      } else {
        debugPrint("Capture: AI response was null or error occurred");
        if (_transcriptChunks.isEmpty) {
          setState(() {
            _isErrorState = true;
            _statusMessage = 'services.capture.statusRetry'.tr();
          });
        }
      }
    } catch (e) {
      debugPrint("Capture: Pipeline error: $e");
      if (mounted && _transcriptChunks.isEmpty) {
        setState(() {
          _isErrorState = true;
          _statusMessage = 'services.capture.statusConnectionError'.tr();
        });
      }
    }
  }

  String _mergeOverlappingStrings(String base, String addition) {
    if (base.isEmpty) return addition;
    
    // Normalize strings: remove punctuation for comparison but keep them in display
    String normalize(String s) => s.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').toLowerCase();
    
    final baseNorm = normalize(base);
    final additionNorm = normalize(addition);
    
    final wordsBase = baseNorm.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordsAdd = additionNorm.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    // Look for overlap in the last 15 words
    int checkCount = wordsBase.length < 15 ? wordsBase.length : 15;
    
    for (int i = checkCount; i >= 1; i--) {
      final suffix = wordsBase.sublist(wordsBase.length - i).join(' ');
      if (additionNorm.startsWith(suffix)) {
        // Found physical overlap. We need to find where that suffix ends in the original 'addition' string
        // Since we normalized, we'll use a more heuristic approach or just find the index of the last word.
        
        // Find how many words to skip in the 'addition'
        int wordsToSkip = i;
        final originalWordsAdd = addition.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (wordsToSkip < originalWordsAdd.length) {
          final newPart = originalWordsAdd.sublist(wordsToSkip).join(' ');
          return "$base $newPart";
        } else {
          return base; // Full overlap
        }
      }
    }
    
    return "$base $addition";
  }

  Future<void> _stopCapture() async {
    _pulseController.stop();
    _pulseController.reset();
    _stopTimer();
    _chunkTimer?.cancel();
    _amplitudeSub?.cancel();
    _streamSub?.cancel();
    _stopHeartbeat();
    setState(() => _isCapturing = false);
    
    await _audioRecorder.stop();

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
    final primaryColor = isDark ? AppColors.accentGreen : AppColors.primaryTeal;
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

