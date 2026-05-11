# ABAN (أبان) - Mosque Live Translation Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Aban is a professional Flutter-based platform designed to bridge the language gap during live mosque sermons (Khutbahs). It provides real-time speech-to-text, translation, and text-to-speech playback for non-Arabic speaking congregants.

---

## 🚀 Key Features

- **Mosque Discovery**: Interactive map and list views to find mosques with live translation.
- **Live Khutbah Stream**: Real-time delivery of translated sermon chunks via Firebase.
- **Professional Translation Pipeline**:
  - **ASR (Speech-to-Text)**: High-fidelity capture for transcription.
  - **Machine Translation**: Near real-time Arabic to multi-language translation.
  - **TTS (Text-to-Speech)**: Integrated local playback with "Auto Speak" and manual speaker controls.
- **Volunteer Dashboard**: Dedicated interface for mosque staff to start/stop live sessions and manage recordings.
- **Archive Management**: Access past sermons with full bilingual transcripts.
- **Quran Integration**: Built-in Quran browser for reference during sermons.
- **Multilingual Support**: Fully localized in English, Arabic, and more using `easy_localization`.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.5+)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Backend**: [Firebase](https://firebase.google.com) (Auth, Firestore, Storage, Functions, Cloud Messaging)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Local Storage**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **AI Services**: Pluggable interface for ASR, NMT, and TTS.

---

## 📂 Project Structure

The project follows a **Feature-Driven Architecture** for maximum scalability and maintainability:

```text
lib/
├── core/               # Global themes, utilities, and router
├── features/           # Independent feature modules (Auth, Mosque, Live, etc.)
│   ├── presentation/   # UI: Screens and Widgets
│   ├── domain/         # Business logic and Entities
│   └── data/           # Repositories and Data Sources
├── providers/          # Global state providers
├── services/           # Pluggable AI and Infrastructure services
└── main.dart           # Entry point
```

---

## ⚙️ Installation & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- [Firebase Project](https://console.firebase.google.com/) configured.
- Google AI Studio (Gemini) API Key (optional for advanced features).

### Steps
1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/aban-flutter.git
   cd aban-flutter
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Secrets**:
   Create a `.env` file in the root directory and add your API keys:
   ```env
   GEMINI_API_KEY=your_gemini_key_here
   ```
4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📱 Running on Different Platforms

- **Mobile (Android/iOS)**: Fully supported with native TTS and background audio capabilities.
- **Web**: Supported with browser-native Speech Synthesis. Ensure `flutter run -d chrome` is used.

---

## 🔮 Future Work

> **Important Note on TTS**: 
> In future versions, **Gemini 3.1 Flash TTS** can be integrated instead of `flutter_tts`. This will provide more advanced voice quality, superior multilingual handling, native streaming support, and granular control tailored for the mosque live translation use case. The current version utilizes `flutter_tts` as it provides a free, stable, and low-latency solution suitable for the initial prototype.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 🤝 Contact

**Project Lead**: Norah Abuthnain
**Organization**: Aban Team
