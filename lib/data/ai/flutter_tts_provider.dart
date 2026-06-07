import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/interfaces/ai_interfaces.dart';

class FlutterTtsProvider implements ITextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  double _volume = 1.0;
  bool _isMuted = false;
  bool _isPlaying = false;

  @override
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Standard rate
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(1.0);
    
    // Web optimizations
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });
    _flutterTts.setErrorHandler((_) {
      _isPlaying = false;
    });
    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
    });
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    if (_isMuted || text.isEmpty) return;

    // Stop any current speech and clear browser queue before speaking new text
    await _flutterTts.stop();

    _isPlaying = true;
    final code = languageCode == 'ar' ? 'ar-SA' : 'en-US';
    await _flutterTts.setLanguage(code);

    // Register handlers right before speak to prevent garbage collection issues on Web
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });
    _flutterTts.setErrorHandler((_) {
      _isPlaying = false;
    });
    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
    });
    
    // Trigger synthesis
    await _flutterTts.speak(text);

    // Fallback: Estimate speaking duration (approx. 11 chars/sec for Arabic, 13 chars/sec for English)
    final isArabic = languageCode == 'ar';
    final divisor = isArabic ? 11.0 : 13.0;
    final estimatedSeconds = (text.length / divisor).clamp(1.5, 120.0);
    
    final steps = (estimatedSeconds * 10).toInt();
    for (int i = 0; i < steps; i++) {
      if (!_isPlaying) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isPlaying = false;
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    await _flutterTts.stop();
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (!_isMuted) {
      await _flutterTts.setVolume(volume);
    }
  }

  @override
  Future<void> setMuted(bool isMuted) async {
    _isMuted = isMuted;
    if (isMuted) {
      _isPlaying = false;
      await _flutterTts.stop();
      await _flutterTts.setVolume(0.0);
    } else {
      await _flutterTts.setVolume(_volume);
    }
  }

  @override
  void dispose() {
    _isPlaying = false;
    _flutterTts.stop();
  }
}
