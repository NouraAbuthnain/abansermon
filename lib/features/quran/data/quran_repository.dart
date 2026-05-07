import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/quran_models.dart';

class QuranRepository {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  Future<List<Surah>> getSurahList() async {
    final response = await http.get(Uri.parse('$_baseUrl/surah'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => Surah.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load surah list');
    }
  }

  Future<SurahDetail> getSurahDetail(int number) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/surah/$number/editions/quran-uthmani,en.sahih'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return SurahDetail.fromJson(data);
    } else {
      throw Exception('Failed to load surah');
    }
  }
}
