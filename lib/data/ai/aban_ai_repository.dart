import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/mosque_discovery/domain/mosque.dart';

class AbanAiRepository {
  static const String _baseUrl = 'https://norahmt-aban-ai-backend.hf.space';
  
  /// Uploads audio bytes as a file and returns the translated text pair
  /// Implements 90s timeout and 3 retries with exponential backoff.
  Future<TranscriptLine?> processAudioChunk(List<int> audioBytes, String timeLabel, String extension) async {
    int attempts = 0;
    const int maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      attempts++;
      try {
        final uri = Uri.parse('$_baseUrl/translate-audio');
        final audioFile = http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'chunk.$extension',
        );
        
        var request = http.MultipartRequest('POST', uri);
        request.files.add(audioFile);
        
        print("Aban AI: [DEBUG] Sending request to $uri");
        print("Aban AI: [DEBUG] Filename: chunk.$extension, Bytes: ${audioBytes.length}");
        print("Aban AI: [DEBUG] Attempt: $attempts, Timeout: 90s");
        
        final startTime = DateTime.now();
        final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
        final response = await http.Response.fromStream(streamedResponse);
        final duration = DateTime.now().difference(startTime).inSeconds;
        
        print("Aban AI: [DEBUG] Response received in ${duration}s. Status: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          final data = response.body;
          print("Aban AI Raw Response (Attempt $attempts): $data");
          final json = jsonDecode(data);
          
          final arText = json['arabic_transcription'] ?? '';
          final enText = json['english_translation'] ?? '';
          
          if (arText.toString().trim().isEmpty) {
            print("Aban AI: Empty transcription received on attempt $attempts");
            return null;
          }

          return TranscriptLine(
            ar: arText.toString(),
            en: enText.toString(),
            time: timeLabel,
          );
        } else {
          print("Aban AI Server Error (${response.statusCode}) on attempt $attempts: ${response.body}");
          if (response.statusCode >= 500) {
            // Retry on server errors
            await Future.delayed(Duration(seconds: attempts * 2));
            continue;
          }
          return null;
        }
      } catch (e) {
        print("Aban AI Request Failed (Attempt $attempts): $e");
        if (attempts < maxAttempts) {
          // Exponential backoff
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }
      }
    }
    return null;
  }
}
