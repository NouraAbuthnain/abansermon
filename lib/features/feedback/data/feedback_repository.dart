import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/feedback.dart';

class FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepository(this._firestore);

  Future<void> submitFeedback(UserFeedback feedback) async {
    await _firestore.collection('feedback').add(feedback.toMap());
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(FirebaseFirestore.instance);
});
