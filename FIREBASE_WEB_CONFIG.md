# 🔥 Firebase Web Configuration - Quick Setup

## ⚠️ Important: Update Firebase Configuration

Your app is currently using **placeholder Firebase configuration**. To make it work properly, you need to add your actual Firebase project configuration.

## 🚀 Quick Steps

### Option 1: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (auto-generates firebase_options.dart)
flutterfire configure
```

This will:
- Connect to your Firebase project
- Generate proper `firebase_options.dart` file
- Configure all platforms (web, Android, iOS)

### Option 2: Manual Configuration

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project** (or create new one)
3. **Add Web App**:
   - Click on "Web" icon (</>)
   - Register your app
   - Copy the configuration

4. **Get your config** from Firebase Console:
   - Project Settings > General
   - Your apps > Web app
   - Copy the `firebaseConfig` object

5. **Update `lib/firebase_options.dart`**:
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
     appId: '1:123456789:web:abcdef123456',
     messagingSenderId: '123456789',
     projectId: 'your-project-id',
     authDomain: 'your-project-id.firebaseapp.com',
     storageBucket: 'your-project-id.appspot.com',
   );
   ```

## 📋 What You Need from Firebase Console

From your Firebase project settings, copy these values:

| Field | Example | Where to Find |
|-------|---------|---------------|
| `apiKey` | AIzaSyXXX... | Web app config |
| `appId` | 1:123:web:abc | Web app config |
| `messagingSenderId` | 123456789 | Web app config |
| `projectId` | my-sports-app | Project settings |
| `authDomain` | my-sports-app.firebaseapp.com | Web app config |
| `storageBucket` | my-sports-app.appspot.com | Web app config |

## 🌐 Setting Up Firebase Web App

### Step 1: Create/Select Firebase Project
```
1. Go to https://console.firebase.google.com/
2. Click "Add project" or select existing
3. Follow the wizard to create project
```

### Step 2: Add Web App
```
1. In Firebase Console, click the web icon (</>)
2. Register app with a nickname (e.g., "Sports Event Web")
3. Copy the configuration shown
4. Click "Continue to console"
```

### Step 3: Enable Services
```
1. Authentication:
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"
   
2. Firestore:
   - Go to Firestore Database
   - Click "Create database"
   - Start in test mode (for now)
   
3. Update Firestore Rules:
   - Copy rules from FIRESTORE_RULES.md
   - Paste in Rules tab
   - Publish
```

### Step 4: Update Configuration
```
1. Open lib/firebase_options.dart
2. Replace placeholder values with your actual config
3. Save the file
4. Restart the app
```

## ✅ Verify Configuration

After updating `firebase_options.dart`:

```bash
# Stop the running app (Ctrl+C in terminal)
flutter run -d chrome
```

If configured correctly:
- ✅ App loads without errors
- ✅ You can browse sports data (public access)
- ✅ Admin login works
- ✅ Data saves to Firestore

## 🐛 Troubleshooting

### Error: "FirebaseOptions cannot be null"
- You haven't updated `firebase_options.dart` yet
- Update with your actual Firebase config

### Error: "Firebase project not found"
- Wrong `projectId` in configuration
- Verify project ID in Firebase Console

### Error: "API key not valid"
- Wrong `apiKey` in configuration  
- Copy correct key from Firebase Console

### Error: "Auth domain not valid"
- Wrong `authDomain` format
- Should be: `your-project-id.firebaseapp.com`

## 📱 Platform-Specific Setup

### Web (Current)
- Already configured once you update `firebase_options.dart`
- No additional files needed

### Android (Future)
- Need `google-services.json` in `android/app/`
- Download from Firebase Console

### iOS (Future)
- Need `GoogleService-Info.plist` in `ios/Runner/`
- Download from Firebase Console

## 🎯 Current Status

Your app has:
- ✅ Firebase initialization code
- ✅ Template firebase_options.dart file
- ⚠️ Placeholder configuration (needs update)
- ⏳ Waiting for your Firebase project config

## 🔜 Next Steps

1. **Create Firebase Project** (5 min)
2. **Add Web App** (2 min)
3. **Copy Configuration** (1 min)
4. **Update firebase_options.dart** (1 min)
5. **Enable Authentication & Firestore** (5 min)
6. **Restart App** (30 sec)

**Total Time: ~15 minutes** ⏱️

## 💡 Pro Tip

Use FlutterFire CLI for automatic configuration:
```bash
flutterfire configure --project=your-project-id
```

This automatically:
- Configures all platforms
- Generates firebase_options.dart
- Downloads config files

---

**Ready to configure? Follow Option 1 or Option 2 above!** 🚀
