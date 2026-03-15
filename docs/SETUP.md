# ABAN (أبان) - Setup & Deployment

## 1. Prerequisites
- Flutter SDK 3.5.0+ installed
- Firebase CLI installed
- Google account for Firebase console

## 2. Environment Configuration Template

A standard `.env` file should be created at the root of the Flutter project for when the mock providers are replaced:

```env
# Pluggable AI Service Provider Configs
GCP_JSON_KEY_PATH="assets/gcp_service_account.json"
GOOGLE_MAPS_API_KEY="AIzaSyAXXXXXXX...."
QURAN_API_URL="https://api.alquran.cloud/v1"
```

## 3. Setup Instructions (Local Dev)
1. Run `flutter clean` and `flutter pub get`.
2. To hook up Firebase, run `flutterfire configure`. (Select your created Firebase project for Web/iOS/Android).
3. Open `lib/core/di/injection_container.dart` where the MockAIProviders are injected. These allow you to run the app right away without API keys.
4. Run `flutter run` on an emulator or physical device.

## 4. Deployment Instructions
- **Firebase Backend**: 
  - Deploy standard rules: `firebase deploy --only firestore:rules`
  - Deploy indexes: `firebase deploy --only firestore:indexes`
  - Deploy functions: `firebase deploy --only functions`
- **Flutter Apps**:
  - Android: `flutter build appbundle --release` -> Upload to Play Console
  - iOS: `flutter build ipa --release` -> Upload via Transporter to App Store Connect.

## 5. Seed Data for Firestore (For Manual Testing)

You can seed the `mosques` collection to test the map and list views:

```json
{
  "mosques": {
    "mosque_101": {
      "name": "Al-Rajhi Grand Mosque",
      "address": "Riyadh, Saudi Arabia",
      "status": "Live",
      "location": {
        "latitude": 24.7136,
        "longitude": 46.6753
      }
    },
    "mosque_102": {
       "name": "King Fahd Mosque",
       "address": "Jeddah, Saudi Arabia",
       "status": "Offline",
       "location": {
           "latitude": 21.5433,
           "longitude": 39.1728
       }
    }
  }
}
```
