# Sports Event Manager

A Flutter application for managing and displaying university sports events with real-time Firebase updates.

## Overview

Sports Event Manager supports two usage modes:

- Public mode: browse sports, matches, and standings without login.
- Admin mode: sign in to manage sports data, teams, and match workflows.

The app uses Firebase for authentication and data storage, and is built with Flutter + BLoC.

## Core Features

### Public access

- Browse sports categories
- View upcoming, live, and completed matches
- Open match details and live score screens
- View standings tables

### Admin access

- Create and manage sports
- Create and manage teams/players
- Schedule matches
- Update scores and complete matches

## Tech Stack

- Flutter (Dart 3, Flutter 3+)
- State management: flutter_bloc, provider (theme state)
- Firebase: firebase_core, firebase_auth, cloud_firestore, firebase_storage
- UI and utilities: flutter_animate, shimmer, lottie, cached_network_image, flutter_svg, intl, image_picker, share_plus, shared_preferences

## Project Structure

```text
lib/
  core/
    models/
    repositories/
    services/
    theme/
    utils/
  features/
    admin/
    auth/
    home/
    scoring/
    splash/
  firebase_options.dart
  main.dart
```

## Data Model (Firestore)

Main collections used by the app:

- users
- sports
- teams
- matches
- standings

Important enum-like values used in code:

- Roles: admin, user
- Match status: upcoming, live, completed, cancelled

## Getting Started

### 1. Prerequisites

- Flutter SDK installed and available in PATH
- A Firebase project (for Auth + Firestore + Storage)
- Android Studio or VS Code

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase setup

This project already contains Firebase wiring files:

- android/app/google-services.json
- lib/firebase_options.dart

If you need to reconfigure Firebase for your own project, run FlutterFire configure and regenerate options.

### 4. Run the app

```bash
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

## App Startup Flow

At launch, the app does the following in main.dart:

1. Initializes Firebase (with timeout handling)
2. Seeds default sports if the sports collection is empty
3. Runs additional app initialization for sport configurations
4. Opens splash screen, then navigates to main screen

## Admin Access Setup

Newly signed-up users are standard users by default.

To grant admin access:

1. Open Firebase Console
2. Go to Firestore users collection
3. Find the user document
4. Set role to admin
5. Sign out and sign in again in the app

## Quality Commands

Analyze project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Troubleshooting

- Build issues: run flutter clean then flutter pub get
- Web run issues: verify Firebase web config in lib/firebase_options.dart
- Auth or data issues: confirm Firestore/Auth are enabled in Firebase project

## Notes

- Package name in pubspec: sports_event_app
- Display app name in code: Sports Event Manager
