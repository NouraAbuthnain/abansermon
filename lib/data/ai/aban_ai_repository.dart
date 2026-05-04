import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/mosque_discovery/domain/mosque.dart';

class AbanAiRepository {
  static const String _baseUrl = 'https://norahmt-aban-ai-backend.hf.space';
  
  /// Uploads audio bytes as a file and returns the translated text pair
  Future<TranscriptLine?> processAudioChunk(List<int> audioBytes, String timeLabel, String extension) async {
    try {
      final uri = Uri.parse('$_baseUrl/translate-audio');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'chunk.$extension',
      ));
      
      final response = await request.send().timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = await response.stream.bytesToString();
        final json = jsonDecode(data);
        
        // If the transcription is empty, skip returning a line
        final arText = json['arabic_transcription'] ?? '';
        final enText = json['english_translation'] ?? '';
        if (arText.toString().trim().isEmpty) return null;

        return TranscriptLine(
          ar: arText,
          en: enText,
          time: timeLabel,
        );
      } else if (response.statusCode == 503) {
        print("Aban AI: Models are still loading...");
        return null; 
      } else {
        print("Aban AI Server Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Aban AI Request Failed: $e");
      return null; 
    }
  }
}
