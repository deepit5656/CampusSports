# 🛠️ Useful Commands - Sports Event Manager

## Flutter Commands

### Setup & Installation
```bash
# Check Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Clean build files
flutter clean

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

### Running the App
```bash
# Run on connected device
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices

# Run with verbose logging
flutter run -v

# Hot reload (during development)
# Press 'r' in terminal

# Hot restart (during development)
# Press 'R' in terminal
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build APK (split per ABI for smaller size)
flutter build apk --split-per-abi

# Build App Bundle (for Play Store)
flutter build appbundle

# Build for iOS
flutter build ios

# Build for web
flutter build web

# Build with release optimization
flutter build apk --release

# Build with debug symbols
flutter build apk --debug
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Analysis & Formatting
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Format specific file
flutter format lib/main.dart

# Check formatting without applying
flutter format --set-exit-if-changed lib/
```

## Firebase Commands

### FlutterFire CLI
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for the project
flutterfire configure

# Update Firebase configuration
flutterfire configure --force
```

### Firebase CLI
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# View Firestore data
firebase firestore:get /users

# Deploy Cloud Functions
firebase deploy --only functions

# View logs
firebase functions:log
```

## Git Commands (Version Control)

### Initial Setup
```bash
# Initialize git repository
git init

# Add all files
git add .

# First commit
git commit -m "Initial commit: Complete Sports Event Manager App"

# Add remote repository
git remote add origin <your-repo-url>

# Push to remote
git push -u origin main
```

### Daily Workflow
```bash
# Check status
git status

# Add modified files
git add .

# Commit changes
git commit -m "Your commit message"

# Push to remote
git push

# Pull latest changes
git pull

# Create new branch
git checkout -b feature/your-feature

# Switch branches
git checkout main

# Merge branch
git merge feature/your-feature

# View commit history
git log --oneline
```

## VS Code Tasks (if using VS Code)

Add to `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Flutter: Run",
      "type": "shell",
      "command": "flutter run",
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "Flutter: Build APK",
      "type": "shell",
      "command": "flutter build apk --split-per-abi"
    },
    {
      "label": "Flutter: Clean & Get",
      "type": "shell",
      "command": "flutter clean && flutter pub get"
    }
  ]
}
```

## Android Commands

### Emulator
```bash
# List available AVDs
emulator -list-avds

# Start specific emulator
emulator -avd <avd-name>

# Start emulator with wipe data
emulator -avd <avd-name> -wipe-data

# Check running emulators
adb devices
```

### ADB (Android Debug Bridge)
```bash
# Check connected devices
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Uninstall app
adb uninstall com.example.sports_event_app

# Clear app data
adb shell pm clear com.example.sports_event_app

# View logs
adb logcat

# View Flutter logs only
adb logcat | grep flutter

# Take screenshot
adb exec-out screencap -p > screenshot.png

# Record screen
adb shell screenrecord /sdcard/demo.mp4
```

### Gradle
```bash
# Navigate to android directory
cd android

# Clean gradle
./gradlew clean

# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease

# List gradle tasks
./gradlew tasks
```

## iOS Commands (macOS only)

### Pods
```bash
# Navigate to iOS directory
cd ios

# Install pods
pod install

# Update pods
pod update

# Deintegrate pods
pod deintegrate

# Clean pods
pod cache clean --all
```

### Simulator
```bash
# List available simulators
xcrun simctl list

# Boot simulator
xcrun simctl boot <device-id>

# Open Simulator app
open -a Simulator

# Install app
xcrun simctl install booted <path-to-app>

# Uninstall app
xcrun simctl uninstall booted <bundle-id>
```

### Xcode
```bash
# Open workspace in Xcode
open ios/Runner.xcworkspace

# Clean build
xcodebuild clean

# Build project
xcodebuild build -workspace ios/Runner.xcworkspace -scheme Runner
```

## Useful Debugging Commands

### Flutter DevTools
```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Open DevTools automatically with app
flutter run --devtools
```

### Performance
```bash
# Profile app performance
flutter run --profile

# Enable observatory
flutter run --enable-observatory

# Trace Dart VM
flutter run --trace-startup
```

## Package Management

### Add Package
```bash
# Add package
flutter pub add <package-name>

# Add dev package
flutter pub add --dev <package-name>

# Add specific version
flutter pub add <package-name>:<version>
```

### Remove Package
```bash
# Remove package
flutter pub remove <package-name>
```

### Update Package
```bash
# Update specific package
flutter pub upgrade <package-name>

# Update all packages
flutter pub upgrade

# Update to latest compatible
flutter pub upgrade --major-versions
```

## Project Maintenance

### Code Generation (if using build_runner)
```bash
# Generate code once
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch

# Clean and rebuild
flutter pub run build_runner build --delete-conflicting-outputs
```

### Internationalization
```bash
# Generate translations
flutter pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/main.dart

# Generate translation files
flutter pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/main.dart lib/l10n/intl_*.arb
```

## Quick Troubleshooting Commands

### Reset Everything
```bash
# Complete reset
flutter clean
cd ios && pod deintegrate && pod cache clean --all && cd ..
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Fix Android Issues
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Fix iOS Issues (macOS)
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

## Firebase Emulator (for local testing)

```bash
# Install Firebase emulators
firebase init emulators

# Start emulators
firebase emulators:start

# Start specific emulator
firebase emulators:start --only firestore

# Export data
firebase emulators:export ./data

# Import data
firebase emulators:start --import ./data
```

## Performance Profiling

```bash
# Build with debug symbols
flutter build apk --debug

# Profile widget rebuilds
flutter run --profile --trace-skia

# Measure app size
flutter build apk --analyze-size

# Check for missing dependencies
flutter doctor --verbose
```

## Shortcuts During Development

When `flutter run` is active:

- `r` - Hot reload
- `R` - Hot restart
- `h` - Display help
- `q` - Quit
- `p` - Show performance overlay
- `P` - Show performance overlay for specific layer
- `o` - Toggle platform (Android/iOS)
- `s` - Save screenshot
- `w` - Dump widget hierarchy
- `t` - Dump rendering tree
- `L` - Dump layer tree

## Environment Variables

### Set Flutter Path (if needed)
```bash
# macOS/Linux
export PATH="$PATH:`pwd`/flutter/bin"

# Windows (PowerShell)
$env:PATH += ";C:\path\to\flutter\bin"
```

### Set Android SDK
```bash
# macOS/Linux
export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Windows
setx ANDROID_HOME "C:\Users\YourUser\AppData\Local\Android\Sdk"
```

---

## Pro Tips

1. Use `flutter pub get` after changing `pubspec.yaml`
2. Run `flutter clean` when facing weird issues
3. Use `--verbose` flag for detailed error messages
4. Keep Flutter SDK updated: `flutter upgrade`
5. Use `flutter doctor -v` to check setup
6. Enable hot reload for faster development
7. Use DevTools for performance profiling
8. Test on both emulator and real device

---

**Save this file for quick reference during development! 📚**
