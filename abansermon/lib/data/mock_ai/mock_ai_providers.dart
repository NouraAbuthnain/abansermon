import 'dart:async';
import '../../domain/interfaces/ai_interfaces.dart';

class MockASRProvider implements IAudioTranscriptionService {
  Timer? _timer;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  int _counter = 0;

  final List<String> _mockSentences = [
    "بسم الله الرحمن الرحيم",
    "الحمد لله رب العالمين",
    "اللهم صل وسلم على نبينا محمد",
    "السلام عليكم ورحمة الله وبركاته",
  ];

  @override
  Future<void> initialize() async {
    // Mock setup
  }

  @override
  Future<void> startCapture() async {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_controller.isClosed) {
        String sentence = _mockSentences[_counter % _mockSentences.length];
        _controller.add(sentence);
        _counter++;
      }
    });
  }

  @override
  Stream<String> subscribeToTranscription() {
    return _controller.stream;
  }

  @override
  Future<void> stopCapture() async {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

class MockTranslationProvider implements ITranslationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String> translateSentence(
      String text, String targetLanguageCode) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Very simple lookup for the mock strings to simulate translation
    if (text.contains("بسم الله")) return "In the name of Allah";
    if (text.contains("الحمد لله")) return "All praise is to Allah";
    if (text.contains("اللهم صل"))
      return "Peace and blessings upon our Prophet Muhammad";
    if (text.contains("السلام عليكم")) return "Peace be upon you all";

    return "[Mock Translation in $targetLanguageCode]: $text";
  }

  @override
  void dispose() {}
}

class MockTTSProvider implements ITextToSpeechService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text, String languageCode) async {
    // In a real implementation this would generate audio bytes and play them.
    // For now we simulate time taken to speak.
    print("Mock TTS Playing: $text in $languageCode");
    await Future.delayed(
        Duration(seconds: text.split(' ').length)); // rough proxy
  }

  @override
  Future<void> stop() async {
    print("Mock TTS Stopped");
  }

  @override
  void dispose() {}
}
