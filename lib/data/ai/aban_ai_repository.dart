import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/mosque_discovery/domain/mosque.dart';

/// Client for the Aban AI FastAPI backend on Hugging Face Spaces.
///
/// POST /translate-audio  (multipart, field name: "audio")
/// Response:
/// {
///   "arabic_transcription": "...",
///   "detected_type": "quran" | "hadith" | "normal",
///   "translations": [ {"language": "en"|"ur"|"bn", "text": "...", "source_used": "lookup"|"nmt"} ],
///   "metadata": { "surah": 30, "ayah_start": 41, "ayah_end": 41, "score": 100, "is_duplicate": true? },
///   "latency_ms": {...}
/// }
class AbanAiRepository {
  static final String _baseUrl =
      dotenv.env['ABAN_AI_BACKEND_URL'] ?? 'https://norahmt-aban-ai-backend.hf.space';

  static const int _maxAttempts = 3;
  static const Duration _timeout = Duration(seconds: 90);

  /// Returns true once the Space has finished loading its models.
  /// Call this before starting a capture session to wake a sleeping Space.
  Future<bool> isReady() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return false;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['models_loaded'] == true;
    } catch (e) {
      debugPrint('Aban AI: health check failed: $e');
      return false;
    }
  }

  /// Uploads one audio chunk and returns a [TranscriptLine] with
  /// Arabic + English/Urdu/Bengali translations.
  ///
  /// Returns null when there is nothing to show (silence, empty transcription,
  /// or a Quran/Hadith the backend marked as a duplicate of the previous chunk).
  Future<TranscriptLine?> processAudioChunk(
      List<int> audioBytes, String timeLabel, String extension) async {
    final uri = Uri.parse('$_baseUrl/translate-audio');

    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final request = http.MultipartRequest('POST', uri)
          ..files.add(http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: 'chunk.$extension',
          ));

        final started = DateTime.now();
        final streamed = await request.send().timeout(_timeout);
        final response = await http.Response.fromStream(streamed);
        debugPrint('Aban AI: ${response.statusCode} in '
            '${DateTime.now().difference(started).inMilliseconds}ms (attempt $attempt)');

        if (response.statusCode == 200) {
          // utf8 decode explicitly so Arabic/Urdu/Bengali never get mangled
          final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          return _parse(json, timeLabel);
        }

        // 503 = models still loading (cold start). 5xx = transient. Retry both.
        if (response.statusCode == 503 || response.statusCode >= 500) {
          debugPrint('Aban AI: server not ready/error: ${response.body}');
          await Future.delayed(Duration(seconds: attempt * (response.statusCode == 503 ? 5 : 2)));
          continue;
        }

        // 4xx (e.g. 422 bad upload) — retrying won't help.
        debugPrint('Aban AI: client error ${response.statusCode}: ${response.body}');
        return null;
      } catch (e) {
        debugPrint('Aban AI: request failed (attempt $attempt): $e');
        if (attempt < _maxAttempts) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    return null;
  }

  TranscriptLine? _parse(Map<String, dynamic> json, String timeLabel) {
    final ar = (json['arabic_transcription'] ?? '').toString().trim();
    if (ar.isEmpty) return null;

    final metadata = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};

    // Backend already sent this verse/hadith in the previous chunk —
    // its translation text is just a "[Duplicate ... skipped]" placeholder.
    if (metadata['is_duplicate'] == true) {
      debugPrint('Aban AI: duplicate ${json['detected_type']} skipped');
      return null;
    }

    final byLang = <String, String>{};
    for (final item in (json['translations'] as List? ?? const [])) {
      if (item is Map) {
        final lang = item['language']?.toString();
        final text = item['text']?.toString().trim() ?? '';
        if (lang != null) byLang[lang] = text;
      }
    }

    final type = (json['detected_type'] ?? 'normal').toString();

    return TranscriptLine(
      ar: ar,
      en: byLang['en'] ?? '',
      ur: byLang['ur'] ?? '',
      bn: byLang['bn'] ?? '',
      time: timeLabel,
      type: type,
      reference: _reference(type, metadata),
    );
  }

  /// "30:41" or "30:41-43" for Quran, hadith id for Hadith.
  String? _reference(String type, Map<String, dynamic> m) {
    if (type == 'quran' && m['surah'] != null) {
      final start = m['ayah_start'];
      final end = m['ayah_end'];
      final ayah = (end != null && end != start) ? '$start-$end' : '$start';
      return '${m['surah']}:$ayah';
    }
    if (type == 'hadith' && m['hadith_id'] != null) {
      return m['hadith_id'].toString();
    }
    return null;
  }
}
