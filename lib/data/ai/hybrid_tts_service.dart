import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/interfaces/ai_interfaces.dart';
import 'google_cloud_tts_provider.dart';
import 'flutter_tts_provider.dart';

class HybridTtsService implements ITextToSpeechService {
  final GoogleCloudTtsProvider _gcpProvider;
  final FlutterTtsProvider _nativeProvider;
  
  bool _isGcpHealthy = true;
  Timer? _recoveryTimer;

  HybridTtsService({
    GoogleCloudTtsProvider? gcpProvider,
    FlutterTtsProvider? nativeProvider,
  })  : _gcpProvider = gcpProvider ?? GoogleCloudTtsProvider(),
        _nativeProvider = nativeProvider ?? FlutterTtsProvider();

  bool get isGcpHealthy => _isGcpHealthy;

  @override
  Future<void> initialize() async {
    await _gcpProvider.initialize();
    await _nativeProvider.initialize();
    _startRecoveryTimer();
  }

  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isGcpHealthy) {
        debugPrint("HybridTtsService: Attempting auto-recovery check for GCP TTS...");
        // Reset GCP to healthy state so the next speak attempt will try it.
        _isGcpHealthy = true;
      }
    });
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    if (_isGcpHealthy) {
      try {
        debugPrint("HybridTtsService: Routing speak request to GCP TTS...");
        await _gcpProvider.speak(text, languageCode);
        return; // Success
      } catch (e) {
        debugPrint("HybridTtsService: GCP TTS failed: $e. Tripping circuit breaker to DEGRADED...");
        _isGcpHealthy = false;
        // Stop GCP player just in case it is half-started/buffering
        try {
          await _gcpProvider.stop();
        } catch (_) {}
      }
    }

    debugPrint("HybridTtsService: Routing speak request to Device Native TTS...");
    try {
      await _nativeProvider.speak(text, languageCode);
    } catch (e) {
      debugPrint("HybridTtsService: Device Native TTS failed: $e");
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await _gcpProvider.stop();
    await _nativeProvider.stop();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _gcpProvider.setVolume(volume);
    await _nativeProvider.setVolume(volume);
  }

  @override
  Future<void> setMuted(bool isMuted) async {
    await _gcpProvider.setMuted(isMuted);
    await _nativeProvider.setMuted(isMuted);
  }

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    _gcpProvider.dispose();
    _nativeProvider.dispose();
  }
}
