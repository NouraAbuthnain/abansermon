import 'package:get_it/get_it.dart';
import '../../domain/interfaces/ai_interfaces.dart';
import '../../data/mock_ai/mock_ai_providers.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  // Setup pluggable AI Services
  // For production, you will conditionally load GCP / OpenAI variants here

  sl.registerLazySingleton<IAudioTranscriptionService>(() => MockASRProvider());
  sl.registerLazySingleton<ITranslationService>(
      () => MockTranslationProvider());
  sl.registerLazySingleton<ITextToSpeechService>(() => MockTTSProvider());
}
