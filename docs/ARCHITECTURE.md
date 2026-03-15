# ABAN (أبان) - Overall Product Architecture

Aban is a mobile-first real-time Khutbah translation platform, facilitating non-Arabic-speaking Muslims to understand Friday sermons in real-time.

## 1. High-Level Architecture

The system consists of three main components:
1. **Frontend (Flutter App)**: Used by both Guests (Listeners) and Volunteers (Broadcasters).
2. **Backend (Firebase)**: Provides authentication, real-time database, cloud functions, and analytics.
3. **Pluggable AI Services**: Handles ASR (Automatic Speech Recognition), MT (Machine Translation), and TTS (Text-To-Speech). These are abstracted via adapters.

### Communication Flow
- **Volunteer -> App -> Firebase**: Volunteers stream audio/text chunks to Firestore or Cloud Storage (depending on the implementation). A background Cloud Function or the volunteer's app acts as the client to the ASR and Translation APIs. For this MVP, we assume the Volunteer app might call the abstraction layer directly, or it proxies through Cloud Functions.
- **Firebase -> Guest**: Guests listen to changes in Firestore `live_sessions` and `translation_chunks` collections.
- **Guest (Audio)**: Guests receive translation text and the TTS abstraction plays it.

## 2. Flutter App Architecture

We follow a Feature-based Clean Architecture:

```
lib/
├── core/                   # App-wide definitions
│   ├── constants/          # Colors, Strings, Dimensions
│   ├── theme/              # Design System
│   ├── network/            # API clients, Firebase instances
│   ├── error/              # Failure handling
│   ├── utils/              # Helpers
│   └── di/                 # Dependency Injection (e.g., get_it)
├── features/               # Feature Modules
│   ├── auth/               # Volunteer auth & roles
│   ├── mosque_discovery/   # Search (List + Map)
│   ├── live_khutbah/       # Streaming, Audio playback
│   ├── quran/              # Quran browsing & API integration
│   ├── settings/           # Localization, Accessibility
│   └── volunteer_dashboard/# Mosque management, Live capture
└── main.dart               # Entry point
```

Each feature module contains:
- `data/`: Repositories implementations, Data Sources (Firebase, APIs), Models
- `domain/`: Entities, Repositories interfaces, Use Cases
- `presentation/`: BLoC/Cubit/Riverpod/Provider state, Screens, Widgets

## 3. Pluggable AI Service Architecture

The core constraint is to NOT couple the app to specific AI models.

### Interfaces
- `IAudioTranscriptionService`: Takes audio chunks, returns text.
- `ITranslationService`: Takes source text, returns localized text.
- `ITextToSpeechService`: Takes text, returns playable audio.

### Adapters
During MVP, we will use `MockASRProvider`, `MockTranslationProvider`, and `MockTTSProvider`. Later, these can be replaced by injecting `GcpASRProvider` or `OpenAITranslationProvider` via the Dependency Injection container (e.g., `get_it`).

## 4. Quran API Integration Layer
A clean provider/service layer decoupled from the UI:
- `IQuranRepository`
- `QuranRemoteDataSource` (Could proxy via Cloud Function or directly to a public API like Alquran.cloud)

## 5. Security and Scaling

- **Role-Based Access**: Firebase Auth Custom Claims or a `roles` document to ensure only Volunteers can create sessions.
- **Real-time Latency**: Firestore real-time listeners for translation chunks. To keep it under 5s, chunks should be small (sentence-level).
- **Scalability**: Document sizes are kept small. Frequent updates happen in a `chunks` subcollection to avoid hitting the 1 write/sec limit on a single document.
