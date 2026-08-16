# Look Book

Look Book is a Flutter app for model discovery and creator profile management. It combines onboarding, auth, profile browsing, posts, reels, messaging, and rate cards into a single mobile experience backed by Firebase.

## What it does

- Firebase authentication with onboarding and email/phone entry flows
- Creator and recruiter-facing profile screens
- Feed, search, notes, and detailed creator views
- Post creation, portfolio uploads, reels, and rate booking flows
- Realtime data, storage, and app check support through Firebase

## Tech Stack

- Flutter 3.x
- Firebase Core, Auth, Database, Storage, and App Check
- Provider for state management
- Shared Preferences for onboarding state
- Image picker, video player, geolocation, audio playback, and messaging-related packages

## Getting Started

### Prerequisites

- Flutter SDK installed
- Firebase project configured for Android, iOS, and Web as needed
- Platform toolchains set up for the targets you want to build

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

If you want a specific device or platform, pass the usual Flutter flags such as `-d <deviceId>`.

## Firebase setup

The app uses `firebase_options.dart` and initializes Firebase in `lib/main.dart`. Make sure your Firebase configuration matches the project you want to run.

The main services in use are:

- Authentication
- Realtime Database
- Storage
- App Check

## Project Structure

- `lib/main.dart` app bootstrap and routing
- `lib/theme/` theme definitions and theme state
- `lib/views/` screens and flows
- `lib/services/` auth, database, storage, search, and messaging logic
- `lib/widgets/` reusable UI pieces
- `assets/` fonts and images
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` platform runners

## Notes

- The app is configured as a private package and is not meant to be published to pub.dev.
- Some screens depend on Firebase data and will behave best once the backend rules and services are configured.
