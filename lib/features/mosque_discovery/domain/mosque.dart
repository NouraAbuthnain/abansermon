import 'package:cloud_firestore/cloud_firestore.dart';
enum MosqueStatus { active, inactive }

/// An archived khutbah record for a specific mosque.
class ArchivedKhutbah {
  final String id;
  final String title;
  final DateTime date;
  final List<TranscriptLine> transcript;
  final String mosqueId;
  final String? imamName;
  final String? topic;
  final String? audioUrl;
  final int? durationSeconds;

  const ArchivedKhutbah({
    required this.id,
    required this.title,
    required this.date,
    required this.transcript,
    required this.mosqueId,
    this.imamName,
    this.topic,
    this.audioUrl,
    this.durationSeconds,
  });

  factory ArchivedKhutbah.fromMap(String id, Map<String, dynamic> map) {
    return ArchivedKhutbah(
      id: id,
      title: map['title'] as String? ?? 'Untitled Khutbah',
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
          : DateTime.now(),
      mosqueId: map['mosqueId'] as String? ?? '',
      imamName: map['imamName'] as String?,
      topic: map['topic'] as String?,
      audioUrl: map['audioUrl'] as String?,
      durationSeconds: map['durationSeconds'] as int?,
      transcript: (map['transcript'] as List<dynamic>?)
              ?.map((e) => TranscriptLine.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'mosqueId': mosqueId,
      if (imamName != null) 'imamName': imamName,
      if (topic != null) 'topic': topic,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'transcript': transcript.map((e) => e.toMap()).toList(),
    };
  }
}


/// One transcript line with its Arabic original and English translation.
/// Populated in phase 2 by the ASR/translation pipeline.
class TranscriptLine {
  final String ar;
  final String en;
  final String time;

  const TranscriptLine({
    required this.ar,
    required this.en,
    required this.time,
  });

  factory TranscriptLine.fromMap(Map<String, dynamic> map) {
    return TranscriptLine(
      ar: map['ar'] as String? ?? '',
      en: map['en'] as String? ?? '',
      time: map['time'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ar': ar,
      'en': en,
      'time': time,
    };
  }
}

class Mosque {
  final String id;
  final String name; // Generic/Fallback name
  final String? nameAr;
  final String? nameEn;
  final String address; // Generic/Fallback address
  final String? addressAr;
  final String? addressEn;
  final double lat;
  final double lng;
  final MosqueStatus status;
  final String distance;
  final String? nextPrayer;
  final String? activeRecorderId;
  final String? imamName;
  final String? topic;
  final String? about;
  final String? aboutAr;
  final String? aboutEn;
  final List<TranscriptLine> transcript;
  final DateTime? lastHeartbeat;

  const Mosque({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.address,
    this.addressAr,
    this.addressEn,
    required this.lat,
    required this.lng,
    required this.status,
    required this.distance,
    this.nextPrayer,
    this.activeRecorderId,
    this.imamName,
    this.topic,
    this.about,
    this.aboutAr,
    this.aboutEn,
    this.transcript = const [],
    this.lastHeartbeat,
  });

  /// Helper to get the localized name based on the current app language.
  String getName(String langCode) {
    if (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    if (langCode == 'en' && nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    // Default fallback
    return nameEn ?? nameAr ?? name;
  }

  /// Helper to get the localized address based on the current app language.
  String getAddress(String langCode) {
    if (langCode == 'ar' && addressAr != null && addressAr!.isNotEmpty) return addressAr!;
    if (langCode == 'en' && addressEn != null && addressEn!.isNotEmpty) return addressEn!;
    // Default fallback
    return addressEn ?? addressAr ?? address;
  }

  /// Helper to get the localized "about" text based on the current app language.
  String getAbout(String langCode) {
    if (langCode == 'ar' && aboutAr != null && aboutAr!.isNotEmpty) return aboutAr!;
    if (langCode == 'en' && aboutEn != null && aboutEn!.isNotEmpty) return aboutEn!;
    // Default fallback
    return aboutEn ?? aboutAr ?? about ?? '';
  }

  bool get isLive {
    if (status != MosqueStatus.active) return false;
    if (lastHeartbeat == null) return false;
    // Heartbeat must be within the last 60 seconds (using abs to handle clock drift)
    final now = DateTime.now();
    final diff = now.difference(lastHeartbeat!).inSeconds.abs();
    return diff < 60;
  }

  bool get isOffline => !isLive;
  bool get isBeingRecorded =>
      activeRecorderId != null && activeRecorderId!.isNotEmpty && isLive;

  /// Deserialise from a Firestore document map.
  factory Mosque.fromMap(String id, Map<String, dynamic> data) {
    return Mosque(
      id: id,
      name: data['name'] as String? ?? '',
      nameAr: data['nameAr'] as String?,
      nameEn: data['nameEn'] as String?,
      address: data['address'] as String? ?? '',
      addressAr: data['addressAr'] as String?,
      addressEn: data['addressEn'] as String?,
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      status: _statusFromString(data['status'] as String?),
      distance: data['distance'] as String? ?? '--',
      activeRecorderId: data['activeRecorderId'] as String?,
      imamName: data['imamName'] as String?,
      topic: data['topic'] as String?,
      about: data['about'] as String?,
      aboutAr: data['aboutAr'] as String?,
      aboutEn: data['aboutEn'] as String?,
      transcript: (data['transcript'] as List<dynamic>?)
              ?.map((e) => TranscriptLine.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastHeartbeat: data['lastHeartbeat'] != null
          ? (data['lastHeartbeat'] as Timestamp).toDate()
          : null,
    );
  }

  /// Serialise to a Firestore-compatible map (no `id` — that is the doc ID).
  Map<String, dynamic> toMap() => {
        'name': name,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'address': address,
        'addressAr': addressAr,
        'addressEn': addressEn,
        'lat': lat,
        'lng': lng,
        'status': _statusToString(status),
        'distance': distance,
        if (activeRecorderId != null) 'activeRecorderId': activeRecorderId,
        if (imamName != null) 'imamName': imamName,
        if (topic != null) 'topic': topic,
        if (about != null) 'about': about,
        if (aboutAr != null) 'aboutAr': aboutAr,
        if (aboutEn != null) 'aboutEn': aboutEn,
        'transcript': transcript.map((e) => e.toMap()).toList(),
        'lastHeartbeat': lastHeartbeat != null ? Timestamp.fromDate(lastHeartbeat!) : null,
      };

  static MosqueStatus _statusFromString(String? s) => switch (s) {
        'active' => MosqueStatus.active,
        _ => MosqueStatus.inactive,
      };

  static String _statusToString(MosqueStatus s) => switch (s) {
        MosqueStatus.active => 'active',
        MosqueStatus.inactive => 'inactive',
      };

  Mosque copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? nameEn,
    String? address,
    String? addressAr,
    String? addressEn,
    double? lat,
    double? lng,
    MosqueStatus? status,
    String? distance,
    String? nextPrayer,
    String? activeRecorderId,
    bool clearRecorder = false,
    String? imamName,
    String? topic,
    String? about,
    List<TranscriptLine>? transcript,
    DateTime? lastHeartbeat,
  }) {
    return Mosque(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      address: address ?? this.address,
      addressAr: addressAr ?? this.addressAr,
      addressEn: addressEn ?? this.addressEn,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      distance: distance ?? this.distance,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      activeRecorderId: clearRecorder
          ? null
          : (activeRecorderId ?? this.activeRecorderId),
      imamName: imamName ?? this.imamName,
      topic: topic ?? this.topic,
      about: about ?? this.about,
      aboutAr: aboutAr ?? this.aboutAr,
      aboutEn: aboutEn ?? this.aboutEn,
      transcript: transcript ?? this.transcript,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
    );
  }
}


enum MosqueFilter { all, live, offline }
