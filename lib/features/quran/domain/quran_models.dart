class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      numberOfAyahs: json['numberOfAyahs'],
      revelationType: json['revelationType'],
    );
  }
}

class Ayah {
  final int number;
  final String text;
  final String translation;
  final int numberInSurah;

  Ayah({
    required this.number,
    required this.text,
    required this.translation,
    required this.numberInSurah,
  });

  factory Ayah.fromJson(Map<String, dynamic> arabicJson, Map<String, dynamic> translationJson) {
    return Ayah(
      number: arabicJson['number'],
      text: arabicJson['text'],
      translation: translationJson['text'],
      numberInSurah: arabicJson['numberInSurah'],
    );
  }
}

class SurahDetail {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<Ayah> ayahs;

  SurahDetail({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    final arabicData = json['data'][0];
    final translationData = json['data'][1];
    
    final List<dynamic> arabicAyahs = arabicData['ayahs'];
    final List<dynamic> translationAyahs = translationData['ayahs'];
    
    List<Ayah> ayahs = [];
    for (int i = 0; i < arabicAyahs.length; i++) {
      ayahs.add(Ayah.fromJson(arabicAyahs[i], translationAyahs[i]));
    }

    return SurahDetail(
      number: arabicData['number'],
      name: arabicData['name'],
      englishName: arabicData['englishName'],
      englishNameTranslation: arabicData['englishNameTranslation'],
      revelationType: arabicData['revelationType'],
      numberOfAyahs: arabicData['numberOfAyahs'],
      ayahs: ayahs,
    );
  }
}
