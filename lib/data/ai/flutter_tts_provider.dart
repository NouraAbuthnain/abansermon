import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/interfaces/ai_interfaces.dart';

class FlutterTtsProvider implements ITextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  double _volume = 1.0;
  bool _isMuted = false;

  Function()? _onComplete;

  @override
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Standard rate
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(1.0);
    
    // Web optimizations
    await _flutterTts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    if (_isMuted || text.isEmpty) return;

    // We can map 'ar' to Arabic and 'en' to English
    final code = languageCode == 'ar' ? 'ar-SA' : 'en-US';
    await _flutterTts.setLanguage(code);
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
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
      await _flutterTts.stop();
      await _flutterTts.setVolume(0.0);
    } else {
      await _flutterTts.setVolume(_volume);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
  }
}
