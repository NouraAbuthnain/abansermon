import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Data class for the volunteer's Firestore profile.
class VolunteerProfile {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final String documentType;
  final String documentNumber;
  final String role;
  final bool isActive;

  const VolunteerProfile({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.documentType,
    required this.documentNumber,
    required this.role,
    required this.isActive,
  });

  factory VolunteerProfile.fromFirestore(Map<String, dynamic> data) {
    return VolunteerProfile(
      uid: data['uid'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      documentType: data['documentType'] as String? ?? '',
      documentNumber: data['documentNumber'] as String? ?? '',
      role: data['role'] as String? ?? 'volunteer',
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  /// First character of fullName, or 'V' as fallback.
  String get initial =>
      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'V';
}

/// Streams the current volunteer's Firestore profile document.
/// Returns `null` when there is no signed-in user or no profile doc.
final volunteerProfileProvider = StreamProvider<VolunteerProfile?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated || authState.userId == null) {
    return Stream.value(null);
  }

  // Dev override path — no real Firestore doc
  if (authState.userId == 'dev_test_user') {
    return Stream.value(const VolunteerProfile(
      uid: 'dev_test_user',
      fullName: 'Dev Volunteer',
      phoneNumber: '+966 500000000',
      documentType: 'auth.docTypes.nationalId',
      documentNumber: '1000000000',
      role: 'volunteer',
      isActive: true,
    ));
  }

  // Real Firestore stream
  final uid = authState.userId!;
  return FirebaseFirestore.instance
      .collection('volunteers')
      .doc(uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return VolunteerProfile.fromFirestore(snap.data()!);
  });
});

/// Convenience: the volunteer's display name (falls back to phone or 'Volunteer').
final volunteerDisplayNameProvider = Provider<String>((ref) {
  final profile = ref.watch(volunteerProfileProvider).valueOrNull;
  if (profile != null && profile.fullName.isNotEmpty) {
    return profile.fullName;
  }
  // Fallback to Firebase Auth phone
  final user = FirebaseAuth.instance.currentUser;
  if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
    return user.phoneNumber!;
  }
  return 'Volunteer';
});
