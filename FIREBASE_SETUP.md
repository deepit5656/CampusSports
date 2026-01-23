# Firebase Configuration

## Setup Instructions

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "Sports Event Manager" (or your preferred name)
4. Follow the setup wizard

### 2. Register Your Flutter App

#### For Android:
1. In Firebase Console, click the Android icon
2. Register app with package name: `com.example.sports_event_app`
3. Download `google-services.json`
4. Place it in `android/app/` directory

#### For iOS:
1. In Firebase Console, click the iOS icon
2. Register app with bundle ID: `com.example.sportsEventApp`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### 3. Enable Authentication

1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method

### 4. Set Up Firestore Database

1. In Firebase Console, go to Firestore Database
2. Click "Create Database"
3. Start in **Test Mode** (for development)
4. Choose a location closest to your users

### 5. Firestore Security Rules

Replace the default rules with these:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Sports collection
    match /sports/{sportId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Teams collection
    match /teams/{teamId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Matches collection
    match /matches/{matchId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Standings collection
    match /standings/{standingId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Tournaments collection
    match /tournaments/{tournamentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 6. Update Android Configuration

Edit `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

Edit `android/app/build.gradle`:
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

### 7. Update iOS Configuration

No additional configuration needed for iOS if you've placed the `GoogleService-Info.plist` correctly.

### 8. FlutterFire CLI (Alternative Method)

You can also use FlutterFire CLI for automatic configuration:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

## Testing

### Create Test Accounts

#### Admin Account:
- Email: `admin@test.com`
- Password: `admin123`
- Role: `admin`

#### User Account:
- Email: `user@test.com`
- Password: `user123`
- Role: `user`

**Note:** You'll need to manually set the role in Firestore after creating the account, or create accounts through the signup flow and manually change the role field in Firestore to 'admin'.

## Troubleshooting

### Common Issues:

1. **Build errors related to Firebase:**
   - Make sure `google-services.json` is in `android/app/`
   - Run `flutter clean` and `flutter pub get`

2. **Authentication not working:**
   - Verify Email/Password is enabled in Firebase Console
   - Check if the app is properly registered

3. **Firestore permission denied:**
   - Verify security rules are properly set
   - Make sure you're signed in before accessing data

4. **iOS build issues:**
   - Run `cd ios && pod install`
   - Make sure `GoogleService-Info.plist` is added to Xcode project
