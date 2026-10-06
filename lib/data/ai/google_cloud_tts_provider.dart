// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/interfaces/ai_interfaces.dart';

class GoogleCloudTtsProvider implements ITextToSpeechService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _volume = 1.0;
  bool _isMuted = false;
  String? _apiKey;

  @override
  Future<void> initialize() async {
    _apiKey = dotenv.env['ABAN_GCP_TTS_API_KEY'];
    await _audioPlayer.setVolume(_volume);
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    if (_isMuted || text.isEmpty) return;
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception("GCP TTS API Key not found.");
    }

    final code = const {
      'ar': 'ar-SA',
      'ur': 'ur-IN',
      'bn': 'bn-IN',
    }[languageCode] ?? 'en-US';
    // Neural2 has no Urdu/Bengali voices; null lets Google pick its default voice
    final voiceName = const {
      'ar-SA': 'ar-SA-Neural2-A',
      'en-US': 'en-US-Neural2-F',
    }[code];

    final response = await http.post(
      Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$_apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'input': {'text': text},
        'voice': {
          'languageCode': code,
          if (voiceName != null) 'name': voiceName,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'sampleRateHertz': 24000,
        },
      }),
    ).timeout(const Duration(milliseconds: 1500));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final audioContent = jsonResponse['audioContent'] as String?;
      if (audioContent != null && audioContent.isNotEmpty) {
        final bytes = base64Decode(audioContent);
        await _playBytes(bytes);
      } else {
        throw Exception("Empty audioContent received from GCP TTS API.");
      }
    } else {
      throw Exception("GCP TTS API error: ${response.statusCode} - ${response.body}");
    }
  }

  Future<void> _playBytes(Uint8List bytes) async {
    final source = MyBufferAudioSource(bytes);
    await _audioPlayer.setAudioSource(source);
    await _audioPlayer.play();
    try {
      await _audioPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed || state == ProcessingState.idle,
      );
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (!_isMuted) {
      await _audioPlayer.setVolume(volume);
    }
  }

  @override
  Future<void> setMuted(bool isMuted) async {
    _isMuted = isMuted;
    if (isMuted) {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(0.0);
    } else {
      await _audioPlayer.setVolume(_volume);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}

class MyBufferAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  MyBufferAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
