# ABAN (أبان) - Realtime Khutbah Translation Platform

Welcome to the development repository for Aban. This is the centralized platform to facilitate non-Arabic-speaking Muslims in understanding the Friday sermons live.

## Features
- **Guest List View**: Filter through Live, Offline, and Pending mosques.
- **Interactive Map Flow**: View live status via map markers in your city and jump straight into a session.
- **Pluggable AI Backend**: ASR, Translation, and TTS architectures have been built via Adapters (`IAudioTranscriptionService`, etc.) to easily switch between Google Cloud APIs, OpenAI, or your own local instances without tightly binding the UI.
- **Real-Time Delivery**: Uses Firestore subcollections representing speech chunks delivered to your client BLoC/Providers.
- **Volunteer Tooling**: Built-in dashboards to manage a Khutbah Capture, toggle session availability, and initiate translations locally.

## Architecture Guidelines
- **UI/UX**: Flutter Material 3 based. Minimalist and respectful color palettes (primary: `#043C40`, secondary: `#50C878`). 
- **Code Organization**: Feature-based separation in `lib/`. 
  - `lib/core`: Theming, APIs, network setup.
  - `lib/features`: View, Domain, Data for specific chunks of the app.
  - `lib/domain/interfaces` - The abstracted interfaces for pluggable services.

## Development Setup
For running the MVP locally using Mock Data dependencies:
1. Refer to `docs/SETUP.md` for exact instructions. 
2. The Firebase Schema is available under `docs/FIREBASE_SCHEMA.md`.

## Next Steps
To implement actual AI Models:
1. Add your desired Dart ASR/TTS/Translation packages to `pubspec.yaml`.
2. Implement instances of `IAudioTranscriptionService`, `ITranslationService`, and `ITextToSpeechService`.
3. In `lib/core/di/injection_container.dart`, swap out `MockASRProvider()` with your new implementations.
