import 'package:cloud_firestore/cloud_firestore.dart';

class UserFeedback {
  final String id;
  final String userId;
  final String khutbahId;
  final int rating; // 1-5
  final List<String> tags;
  final String? comment;
  final DateTime timestamp;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.khutbahId,
    required this.rating,
    this.tags = const [],
    this.comment,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'khutbahId': khutbahId,
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory UserFeedback.fromMap(String id, Map<String, dynamic> map) {
    return UserFeedback(
      id: id,
      userId: map['userId'] ?? '',
      khutbahId: map['khutbahId'] ?? '',
      rating: map['rating'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      comment: map['comment'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
