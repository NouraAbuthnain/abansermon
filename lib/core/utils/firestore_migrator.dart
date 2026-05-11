import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class FirestoreMigrator {
  /// Cleans up legacy localization fields from the 'mosques' collection.
  /// Call this once from a dev menu or temporary button.
  static Future<void> cleanLegacyFields() async {
    dev.log('🚀 Starting Firestore Migration: Cleaning up legacy localization fields...');
    
    final collection = FirebaseFirestore.instance.collection('mosques');
    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) {
      dev.log('❌ No mosques found.');
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Map<String, dynamic> updates = {};

      final fieldsToRemove = [
        'nameAr', 'nameEn', 
        'addressAr', 'addressEn', 
        'aboutAr', 'aboutEn'
      ];

      bool hasChanges = false;
      for (var field in fieldsToRemove) {
        if (data.containsKey(field)) {
          updates[field] = FieldValue.delete();
          hasChanges = true;
        }
      }

      if (hasChanges) {
        batch.update(doc.reference, updates);
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
      dev.log('✅ Successfully cleaned up $count documents.');
    } else {
      dev.log('ℹ️ No documents needed migration.');
    }
  }
}
