# ABAN (أبان) - Firebase Architecture & Schema

## 1. Firebase Products Used
- **Firebase Authentication**: For Volunter registration/login (Guests can be anonymous or unauthenticated).
- **Cloud Firestore**: Real-time database for mosques, live sessions, translation chunks, archives, feedback.
- **Cloud Storage**: To store audio recordings of Khutbahs.
- **Cloud Functions**: For triggering summaries, analytics, syncing indices, and potentially proxying the Quran API.
- **Firebase Cloud Messaging (FCM)**: For notifying guests when a tracked mosque goes live.

## 2. Firestore Schema

### `users` collection
Guests (if using auth) and basic user metadata.
```json
{
  "id": "user_123",
  "role": "guest", // guest, volunteer, admin
  "fcm_tokens": ["token1", "token2"],
  "language_preference": "en",
  "created_at": "timestamp"
}
```

### `volunteer_profiles` collection
Extra metadata for volunteers. Keyed by user ID.
```json
{
  "user_id": "user_123",
  "verified": true,
  "assigned_mosques": ["mosque_456"],
  "total_captures": 15
}
```

### `mosques` collection
The core entity for discovery.
```json
{
  "id": "mosque_456",
  "name": "Al-Rajhi Mosque",
  "location": {
    "latitude": 24.7136,
    "longitude": 46.6753
  },
  "address": "Riyadh, Saudi Arabia",
  "status": "Offline", // Pending | Offline | Live
  "created_by": "user_123",
  "last_active": "timestamp",
  "search_terms": ["alrajhi", "rajhi", "riyadh"]
}
```

### `live_sessions` collection
Temporary docs representing an active capture.
```json
{
  "id": "session_789",
  "mosque_id": "mosque_456",
  "start_time": "timestamp",
  "end_time": null,
  "status": "recording", // recording | ended
  "volunteer_id": "user_123",
  "languages_available": ["en", "ur"]
}
```

#### `live_sessions/{session_id}/translation_chunks` subcollection
Small chunks of text updated rapidly for sub-5 second latency.
```json
{
  "id": "chunk_001",
  "sequence_number": 1,
  "start_time_ms": 0,
  "end_time_ms": 2500,
  "original_arabic": "بسم الله",
  "translations": {
    "en": "In the name of Allah",
    "ur": "اللہ کے نام سے"
  },
  "created_at": "timestamp"
}
```

### `khutbah_archives` collection
Generated when a session ends.
```json
{
  "id": "archive_101",
  "mosque_id": "mosque_456",
  "date": "timestamp",
  "title": "Patience in Islam",
  "audio_url": "gs://bucket/path/to/audio.mp3",
  "languages": ["en", "ur"],
  "summary": {
    "en": "A sermon about the importance of patience..."
  }
}
```

### `feedback` collection
Ratings submitted by users.
```json
{
  "id": "fb_111",
  "session_id": "session_789",
  "user_id": "user_123",
  "rating": 4,
  "comment": "Translation was slightly disconnected at the end.",
  "created_at": "timestamp"
}
```

## 3. Indexes Required
- `mosques` by `status` (Live vs Offline vs Pending).
- `mosques` by `location` (Geohash via GeoFlutterFire / standard Firebase geospatial indexing).
- `translation_chunks` by `sequence_number` ascending.
- `khutbah_archives` by `mosque_id` and `date` descending.

## 4. Security Rules Summary
- `mosques`: Read by everyone. Approvable/updatable only by admin/authorized volunteers. Creating requires `volunteer` role.
- `live_sessions`: Read by everyone. Write only by the `volunteer_id` who started it.
- `translation_chunks`: Read by everyone. Write only by the Cloud Function or the assigned `volunteer_id`.
- `khutbah_archives`: Read by everyone. Immutably created by backend system.
