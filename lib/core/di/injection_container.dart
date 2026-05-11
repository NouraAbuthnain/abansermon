import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import '../../domain/interfaces/ai_interfaces.dart';
import '../../data/mock_ai/mock_ai_providers.dart';
import '../../data/ai/flutter_tts_provider.dart';
import '../../data/ai/aban_ai_repository.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  // Setup pluggable AI Services
  // For production, you will conditionally load GCP / OpenAI variants here

  sl.registerLazySingleton<IAudioTranscriptionService>(() => MockASRProvider());
  sl.registerLazySingleton<ITranslationService>(
      () => MockTranslationProvider());
      
  // Use native Web Speech API and native mobile TTS via flutter_tts.
  // Gemini 3.1 Flash TTS is documented for future integration.
  sl.registerLazySingleton<ITextToSpeechService>(() => FlutterTtsProvider());
  
  sl.registerLazySingleton<AbanAiRepository>(() => AbanAiRepository());
}
