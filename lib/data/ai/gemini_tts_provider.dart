import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/interfaces/ai_interfaces.dart';

class GeminiTtsProvider implements ITextToSpeechService {
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY';

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Future<void> initialize() async {
    // Initialization if necessary
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    if (text.isEmpty) return;
    
    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
      
      final body = {
        "contents": [
          {
            "parts": [
              {"text": text}
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["AUDIO"]
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Extract base64 audio data
        final parts = json['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final inlineData = parts[0]['inlineData'];
          if (inlineData != null && inlineData['mimeType'] != null) {
            final base64String = inlineData['data'] as String;
            final mimeType = inlineData['mimeType'] as String;
            
            // just_audio can play from data URIs
            final uri = Uri.parse('data:$mimeType;base64,$base64String');
            await _audioPlayer.setAudioSource(AudioSource.uri(uri));
            await _audioPlayer.play();
          }
        }
      } else {
        print("Gemini TTS Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Gemini TTS Exception: $e");
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  @override
  Future<void> setMuted(bool isMuted) async {
    if (isMuted) {
      await _audioPlayer.setVolume(0);
    } else {
      // Restore some default or keep track of last volume
      await _audioPlayer.setVolume(1.0);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}
