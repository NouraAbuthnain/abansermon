import 'package:get_it/get_it.dart';
import '../../domain/interfaces/ai_interfaces.dart';
import '../../data/mock_ai/mock_ai_providers.dart';
import '../../data/ai/hybrid_tts_service.dart';
import '../../data/ai/aban_ai_repository.dart';
import '../../data/ai/khutbah_topic_service.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  // Setup pluggable AI Services
  // For production, you will conditionally load GCP / OpenAI variants here

  sl.registerLazySingleton<IAudioTranscriptionService>(() => MockASRProvider());
  sl.registerLazySingleton<ITranslationService>(
      () => MockTranslationProvider());
      
  // Use hybrid TTS service with GCP Neural2 primary and native local fallback
  sl.registerLazySingleton<ITextToSpeechService>(() => HybridTtsService());
  
  sl.registerLazySingleton<AbanAiRepository>(() => AbanAiRepository());
  sl.registerLazySingleton<KhutbahTopicService>(() => KhutbahTopicService());
}

