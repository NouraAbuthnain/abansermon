import 'dart:async';
import 'dart:typed_data';

/// Abstraction for ASR (Automatic Speech Recognition)
abstract class IAudioTranscriptionService {
  Future<void> initialize();

  /// Starts listening to audio and streams transcribed text in Arabic (source language)
  Stream<String> subscribeToTranscription();
  Future<void> startCapture();
  Future<void> stopCapture();
  void dispose();
}

/// Abstraction for Machine Translation (MT)
abstract class ITranslationService {
  Future<void> initialize();

  /// Translates a source string (e.g., Arabic) into target language (e.g., English, Urdu)
  Future<String> translateSentence(String text, String targetLanguageCode);
  void dispose();
}

/// Abstraction for Text-To-Speech (TTS)
abstract class ITextToSpeechService {
  Future<void> initialize();

  /// Takes text and streams back audio bytes or plays it directly
  /// depending on implementation. In MVP, we might play directly.
  Future<void> speak(String text, String languageCode);
  Future<void> stop();
  void dispose();
}
