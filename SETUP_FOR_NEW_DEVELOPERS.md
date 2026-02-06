# 🚀 Setup Instructions for New Developers

## Prerequisites
- Flutter SDK installed
- Dart SDK installed
- Git installed
- Firebase account access (ask project owner)

## 📥 Initial Setup

### 1. Clone the Repository
```bash
git clone https://github.com/deepit5656/CampusSports.git
cd CampusSports
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase (REQUIRED!)

#### **Important**: Firebase configuration files are NOT included in Git for security reasons. You need to create them locally.

#### Option A: Using FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (will create files automatically)
flutterfire configure
```
This will:
- Create `lib/firebase_options.dart`
- Download `android/app/google-services.json`
- Setup iOS configuration if needed

#### Option B: Manual Setup
If you don't have Firebase project access:

1. **Ask the project owner** for Firebase Console access
2. Get the Firebase configuration files from them:
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`

3. Or use the template to create your own Firebase project:
   ```bash
   # Copy the template
   cp lib/firebase_options.dart.template lib/firebase_options.dart
   
   # Edit and add your Firebase credentials
   # Get credentials from: Firebase Console > Project Settings > Your apps
   ```

### 4. Verify Setup
```bash
# Check for errors
flutter analyze

# Run on device/emulator
flutter run
```

## 📁 Required Files (NOT in Git)
These files must exist locally but are excluded from Git:
- ✅ `lib/firebase_options.dart` - Firebase configuration
- ✅ `android/app/google-services.json` - Android Firebase config
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS Firebase config (if using iOS)

## 🔧 Troubleshooting

### Error: "Target of URI doesn't exist: 'package:flutter/material.dart'"
```bash
flutter clean
flutter pub get
```

### Error: "Firebase not configured"
- Ensure `lib/firebase_options.dart` exists
- Verify Firebase credentials are correct
- Check Firebase project is active in Firebase Console

### Error: "google-services.json not found"
- Download from Firebase Console > Project Settings > Android app
- Place in `android/app/google-services.json`

## 🏃 Running the App

### Android
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

### iOS (macOS only)
```bash
cd ios
pod install
cd ..
flutter run
```

## 👥 Getting Firebase Access
Contact the project owner (GitHub: @deepit5656) to:
1. Get added to the Firebase project
2. Receive Firebase configuration files
3. Get Firestore access permissions

## 📝 Development Workflow
```bash
# Pull latest changes
git pull

# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "feat: your feature description"

# Push your branch
git push origin feature/your-feature

# Create Pull Request on GitHub
```

## ⚠️ Important Notes
- **NEVER** commit Firebase credentials to Git
- **NEVER** commit `google-services.json` or `firebase_options.dart`
- Check `.gitignore` before committing
- Always run `git status` to verify what you're committing

## 📚 Useful Commands
```bash
# Clean and rebuild
flutter clean && flutter pub get

# Check for issues
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test
```

## 🔗 Resources
- [Project Repository](https://github.com/deepit5656/CampusSports)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## 🆘 Need Help?
1. Check existing issues on GitHub
2. Read the README.md
3. Contact the project owner
4. Check Flutter/Firebase documentation
