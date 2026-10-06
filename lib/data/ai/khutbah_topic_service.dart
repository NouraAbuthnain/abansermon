import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../core/constants/khutbah_topics.dart';
import '../../features/mosque_discovery/domain/mosque.dart';

class KhutbahTopicService {
  late final GenerativeModel _model;

  KhutbahTopicService({GenerativeModel? model}) {
    if (model != null) {
      _model = model;
    } else {
      final allowedTopics = khutbahTopics.entries
          .map((e) => '- ${e.key}: ${e.value['ar']} / ${e.value['en']}')
          .join('\n');

      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0,
          responseSchema: Schema.object(
            properties: {
              'main_topic': Schema.string(
                description: 'The main topic ID from the allowed list',
              ),
              'secondary_topics': Schema.array(
                items: Schema.string(
                  description: 'Secondary topic IDs from the allowed list',
                ),
              ),
            },
          ),
        ),
        systemInstruction: Content.system(
          'You are a topic classifier for Friday khutbah (sermon) transcripts. '
          'Classify the transcript into topics. You MUST choose ONLY from the following allowed topic IDs:\n'
          '$allowedTopics\n\n'
          'Output JSON ONLY matching the requested schema. Do NOT invent new topic IDs.',
        ),
      );
    }
  }

  Future<({String main, List<String> secondary})?> classify(
      List<TranscriptLine> lines) async {
    try {
      final joinedArabicText = lines
          .map((l) => l.ar.trim())
          .where((t) => t.isNotEmpty)
          .join('\n');

      if (joinedArabicText.isEmpty) {
        return null;
      }

      final cappedText = joinedArabicText.length > 15000
          ? joinedArabicText.substring(0, 15000)
          : joinedArabicText;

      final response = await _model.generateContent([Content.text(cappedText)]);
      final rawJson = response.text;
      if (rawJson != null && rawJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawJson);
          if (decoded is Map<String, dynamic>) {
            final rawMain = decoded['main_topic'] as String?;
            if (rawMain != null && khutbahTopics.containsKey(rawMain)) {
              final rawSecondary = decoded['secondary_topics'];
              final List<String> validSecondary = [];
              if (rawSecondary is List) {
                for (final item in rawSecondary) {
                  if (item is String &&
                      item != rawMain &&
                      khutbahTopics.containsKey(item) &&
                      !validSecondary.contains(item)) {
                    validSecondary.add(item);
                  }
                }
              }
              return (main: rawMain, secondary: validSecondary);
            }
          }
        } catch (e) {
          debugPrint('KhutbahTopicService JSON decode error: $e');
        }
      }
    } catch (e) {
      debugPrint('KhutbahTopicService Gemini error (using keyword fallback): $e');
    }

    // Fallback: simple keyword-based topic classification
    return _fallbackClassify(lines.map((l) => l.ar).join(' '));
  }

  ({String main, List<String> secondary}) _fallbackClassify(String text) {
    final Map<String, List<String>> keywords = {
      'aqeedah': ['عقيدة', 'توحيد', 'إيمان', 'إله', 'شرك', 'رسول', 'رب'],
      'prayer': ['صلاة', 'مسجد', 'وضوء', 'عبادة', 'صيام', 'زكاة', 'ركوع', 'سجود'],
      'hereafter': ['آخرة', 'قبر', 'جنة', 'نار', 'حساب', 'قيامة', 'موت', 'بعث'],
      'patience': ['صبر', 'بلاء', 'ابتلاء', 'صابر', 'مصيبة', 'شدة', 'حرم', 'حرمك'],
      'repentance': ['توبة', 'استغفار', 'ذنب', 'ذنوب', 'غفور', 'رحيم', 'معصية'],
      'gratitude': ['شكر', 'نعم', 'نعمة', 'حمد', 'فضل', 'مشكور'],
      'character': ['أخلاق', 'خلق', 'صدق', 'أمانة', 'معاملة', 'حلم', 'أدب', 'كذب'],
      'family': ['أسرة', 'والدين', 'أب', 'أم', 'أبناء', 'زوج', 'زوجة', 'رحم', 'أرحام'],
      'occasions': ['رمضان', 'عيد', 'جمعة', 'حجة', 'محرم', 'رجب', 'شعبان'],
      'society': ['مجتمع', 'أمن', 'سلام', 'مسلمين', 'تعاون', 'أخوة', 'حقوق'],
    };

    final scores = <String, int>{};
    for (final entry in keywords.entries) {
      int score = 0;
      for (final kw in entry.value) {
        score += kw.allMatches(text).length;
      }
      scores[entry.key] = score;
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final main = (sorted.isNotEmpty && sorted.first.value > 0) ? sorted.first.key : 'character';
    final secondary = sorted
        .skip(1)
        .where((e) => e.value > 0)
        .take(2)
        .map((e) => e.key)
        .toList();

    return (main: main, secondary: secondary);
  }
}
