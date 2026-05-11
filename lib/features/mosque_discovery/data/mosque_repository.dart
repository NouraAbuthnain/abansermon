import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/location_provider.dart';
import '../domain/mosque.dart';

/// Real-time Firestore-backed mosque repository.
///
/// All writes (add, startRecording, stopRecording) hit Firestore and are
/// broadcast to every listening device via the snapshots() stream.
class MosqueRepository extends StreamNotifier<List<Mosque>> {
  static final _col = FirebaseFirestore.instance.collection('mosques');

  @override
  Stream<List<Mosque>> build() {
    return _col.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Mosque.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Adds a mosque to Firestore using its predefined ID.
  /// Uses merge so existing runtime fields (status, activeRecorderId) are
  /// not overwritten if the document already exists.
  Future<void> addMosque(Mosque mosque) async {
    await _col.doc(mosque.id).set(mosque.toMap(), SetOptions(merge: true));
  }

  /// Marks the mosque as actively recording. Visible to all users in real-time.
  Future<void> startRecording(String mosqueId, String recorderId) async {
    final doc = await _col.doc(mosqueId).get();
    if (doc.exists) {
      final mosque = Mosque.fromMap(doc.id, doc.data()!);
      if (mosque.isLive && mosque.activeRecorderId != recorderId) {
        throw Exception('This mosque is already being recorded by another volunteer.');
      }
    }

    await _col.doc(mosqueId).update({
      'status': 'active',
      'activeRecorderId': recorderId,
      'transcript': [], // Clear previous session transcript
      'lastHeartbeat': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the mosque's presence to keep the live status active.
  Future<void> updateHeartbeat(String mosqueId) async {
    await _col.doc(mosqueId).update({
      'lastHeartbeat': FieldValue.serverTimestamp(),
    });
  }

  /// Appends a new translated line to the mosque's transcript.
  Future<void> appendTranscript(String mosqueId, TranscriptLine line) async {
    try {
      print("appendTranscript mosqueId: $mosqueId");
      print("appendTranscript line: ${line.toMap()}");

      await _col.doc(mosqueId).set({
        'transcript': FieldValue.arrayUnion([line.toMap()])
      }, SetOptions(merge: true));

      print("Firestore upload success");
    } catch (e) {
      print("Firestore ERROR: $e");
    }
  }

  /// Clears the recording session. All listeners see the mosque go offline.
  Future<void> stopRecording(String mosqueId) async {
    await _col.doc(mosqueId).update({
      'status': 'inactive',
      'activeRecorderId': null,
    });
  }

  /// Permanently removes the mosque document from Firestore.
  Future<void> deleteMosque(String mosqueId) async {
    await _col.doc(mosqueId).delete();
  }

  /// Saves a khutbah to the mosque's archives subcollection.
  Future<void> saveArchive(String mosqueId, ArchivedKhutbah archive) async {
    final archivesCol = _col.doc(mosqueId).collection('archives');
    // If archive.id is empty, Firestore generates a new ID.
    if (archive.id.isEmpty) {
      await archivesCol.add(archive.toMap());
    } else {
      await archivesCol.doc(archive.id).set(archive.toMap(), SetOptions(merge: true));
    }
  }

  /// Returns a stream of archives for a given mosque.
  Stream<List<ArchivedKhutbah>> getArchives(String mosqueId) {
    return _col
        .doc(mosqueId)
        .collection('archives')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ArchivedKhutbah.fromMap(doc.id, doc.data()))
            .toList());
  }
}

final mosqueRepositoryProvider =
    StreamNotifierProvider<MosqueRepository, List<Mosque>>(
        MosqueRepository.new);

/// A provider that ticks every 10 seconds to force UI updates for time-dependent fields (like isLive).
final statusRefreshTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (count) => count);
});

final mosqueQueryProvider = StateProvider<String>((ref) => '');

final mosqueFilterProvider =
    StateProvider<MosqueFilter>((ref) => MosqueFilter.all);

String _formatDistance(Position? pos, Mosque m) {
  if (pos == null) return '--';
  final meters = Geolocator.distanceBetween(
      pos.latitude, pos.longitude, m.lat, m.lng);
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

double _distanceMeters(Position pos, Mosque m) =>
    Geolocator.distanceBetween(pos.latitude, pos.longitude, m.lat, m.lng);

final filteredMosquesProvider = Provider<List<Mosque>>((ref) {
  // Watch the repository for data changes
  final all = ref.watch(mosqueRepositoryProvider).valueOrNull ?? [];
  // Watch the tick to force re-evaluation of isLive periodically
  ref.watch(statusRefreshTickProvider);
  
  final userPos = ref.watch(userLocationProvider).valueOrNull;
  final query = ref.watch(mosqueQueryProvider).trim().toLowerCase();
  final filter = ref.watch(mosqueFilterProvider);

  // Inject real distance into each mosque object.
  Iterable<Mosque> list = all
      .map((m) => m.copyWith(distance: _formatDistance(userPos, m)));

  switch (filter) {
    case MosqueFilter.all:
      break;
    case MosqueFilter.live:
      list = list.where((m) => m.isLive);
      break;
    case MosqueFilter.offline:
      list = list.where((m) => m.isOffline);
      break;
  }

  if (query.isNotEmpty) {
    list = list.where((m) =>
        m.getLocalizedName().toLowerCase().contains(query) ||
        m.getLocalizedAddress().toLowerCase().contains(query));
  }

  // Sort: Live mosques first, then by distance (if available), then by name.
  final result = list.toList();
  result.sort((a, b) {
    if (a.isLive && !b.isLive) return -1;
    if (!a.isLive && b.isLive) return 1;

    if (userPos != null) {
      final distA = _distanceMeters(userPos, a);
      final distB = _distanceMeters(userPos, b);
      return distA.compareTo(distB);
    }
    return a.getLocalizedName().compareTo(b.getLocalizedName());
  });

  return result;
});

/// Whether the mosques stream is in its initial loading state.
final mosquesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(mosqueRepositoryProvider).isLoading;
});

/// A provider that returns the count of currently live mosques, refreshed every 10s.
final liveMosqueCountProvider = Provider<int>((ref) {
  final mosques = ref.watch(mosqueRepositoryProvider).valueOrNull ?? [];
  ref.watch(statusRefreshTickProvider);
  return mosques.where((m) => m.isLive).length;
});
