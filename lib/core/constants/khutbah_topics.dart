/// Const map of topic id -> localized topic names {ar, en, ur, bn}.
const Map<String, Map<String, String>> khutbahTopics = {
  'aqeedah': {
    'ar': 'العقيدة والتوحيد',
    'en': 'Aqeedah & Monotheism',
    'ur': 'عقیدہ اور توحید', // TODO: verify translation
    'bn': 'আকিদা ও তাওহীদ', // TODO: verify translation
  },
  'prayer': {
    'ar': 'الصلاة والعبادات',
    'en': 'Prayer & Worship',
    'ur': 'نماز اور عبادات', // TODO: verify translation
    'bn': 'সালাত ও ইবাদাত', // TODO: verify translation
  },
  'hereafter': {
    'ar': 'الآخرة ويوم القيامة',
    'en': 'Hereafter & Day of Judgment',
    'ur': 'آخرت اور روزِ قيامت', // TODO: verify translation
    'bn': 'আখেরات ও কিয়ামত', // TODO: verify translation
  },
  'patience': {
    'ar': 'الصبر والابتلاء',
    'en': 'Patience & Trials',
    'ur': 'صبر اور آزمائش', // TODO: verify translation
    'bn': 'ধৈর্য ও পরীক্ষা', // TODO: verify translation
  },
  'repentance': {
    'ar': 'التوبة والاستغفار',
    'en': 'Repentance & Seeking Forgiveness',
    'ur': 'توبہ اور استغفار', // TODO: verify translation
    'bn': 'তওবা ও এস্তেগফার', // TODO: verify translation
  },
  'gratitude': {
    'ar': 'الشكر والنعم',
    'en': 'Gratitude & Blessings',
    'ur': 'شکر اور نعمتیں', // TODO: verify translation
    'bn': 'কৃতজ্ঞতা ও নেয়ামত', // TODO: verify translation
  },
  'character': {
    'ar': 'الأخلاق والمعاملات',
    'en': 'Character & Conduct',
    'ur': 'اخلاق اور معاملات', // TODO: verify translation
    'bn': 'চরিত্র ও সামাজিক আচরণ', // TODO: verify translation
  },
  'family': {
    'ar': 'الأسرة وصلة الرحم',
    'en': 'Family & Kinship',
    'ur': 'خاندان اور صلہ رحمی', // TODO: verify translation
    'bn': 'পরিবার ও আত্মীয়তার সম্পর্ক', // TODO: verify translation
  },
  'occasions': {
    'ar': 'المناسبات',
    'en': 'Occasions',
    'ur': 'مناسبات', // TODO: verify translation
    'bn': 'উপলক্ষে و অনুষ্ঠান', // TODO: verify translation
  },
  'society': {
    'ar': 'المجتمع والأمن',
    'en': 'Society & Security',
    'ur': 'معاشرہ اور امن', // TODO: verify translation
    'bn': 'সমাজ ও নিরাপত্তা', // TODO: verify translation
  },
};

/// Helper function to retrieve the topic display name for a given language.
/// Fallback order: languageCode -> 'en' -> topicId itself.
String getTopicDisplayName(String topicId, String languageCode) {
  final translations = khutbahTopics[topicId];
  if (translations == null) return topicId;
  return translations[languageCode] ?? translations['en'] ?? topicId;
}
