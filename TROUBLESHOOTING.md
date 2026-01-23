# 🔧 Troubleshooting Guide - Sports Event Manager

## Common Issues and Solutions

### 🚨 Build Errors

#### Issue: "No Firebase App has been created"
**Symptoms:** App crashes on startup with Firebase error

**Solution:**
1. Verify `google-services.json` is in `android/app/` directory
2. Verify `GoogleService-Info.plist` is in `ios/Runner/` directory
3. Make sure you've called `Firebase.initializeApp()` in `main.dart`
4. Run:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

#### Issue: "Could not resolve firebase_core"
**Symptoms:** Build fails with dependency error

**Solution:**
1. Check internet connection
2. Clear pub cache:
   ```bash
   flutter pub cache repair
   flutter pub get
   ```
3. Check `pubspec.yaml` for correct Firebase versions

#### Issue: Android build fails with Gradle error
**Symptoms:** Build stops with Gradle-related error

**Solution:**
1. Navigate to android directory:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   ```
2. Update `android/build.gradle` with correct Kotlin and Gradle versions
3. Check `minSdkVersion` is 21 or higher in `android/app/build.gradle`
4. Run `flutter clean && flutter pub get`

#### Issue: iOS build fails with Pod error (macOS only)
**Symptoms:** Pod install fails or build error

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
pod cache clean --all
pod install
cd ..
flutter clean
flutter pub get
```

---

### 🔐 Authentication Issues

#### Issue: "USER_NOT_FOUND" or "WRONG_PASSWORD"
**Symptoms:** Can't login with credentials

**Solution:**
1. Check if user exists in Firebase Console → Authentication
2. Verify email/password are correct
3. Make sure Email/Password authentication is enabled in Firebase
4. Try creating a new account
5. Check for typos in email address

#### Issue: Can't create account
**Symptoms:** Signup fails silently or with error

**Solution:**
1. Enable Email/Password in Firebase Console → Authentication
2. Check password is at least 6 characters
3. Verify email format is valid
4. Check Firebase Console for error logs
5. Ensure Firestore has proper write permissions

#### Issue: User role not persisting
**Symptoms:** User role not saved or incorrect

**Solution:**
1. Check Firestore Console → users collection
2. Verify role field is 'admin' or 'user' (lowercase)
3. Manually update role in Firestore if needed:
   - Go to Firestore Console
   - Find your user document
   - Edit `role` field to 'admin' or 'user'

---

### 💾 Firestore Issues

#### Issue: "Permission Denied" when accessing Firestore
**Symptoms:** Can't read or write data

**Solution:**
1. Check Firestore Rules in Firebase Console
2. Ensure you're logged in (authentication required)
3. Verify rules allow authenticated users
4. For development, temporarily use test mode:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
5. Remember to update rules for production!

#### Issue: Data not showing in app
**Symptoms:** Empty lists or no data displayed

**Solution:**
1. Check if data exists in Firebase Console → Firestore
2. Verify collection names match:
   - `users`
   - `sports`
   - `teams`
   - `matches`
   - `standings`
3. Check for console errors
4. Verify you're logged in
5. Pull to refresh the screen
6. Restart the app

#### Issue: Real-time updates not working
**Symptoms:** Data doesn't update automatically

**Solution:**
1. Check internet connection
2. Verify StreamBuilder is used correctly
3. Check Firebase Console for any service issues
4. Restart the app
5. Check for errors in console

---

### 📱 UI/Display Issues

#### Issue: Gradient colors not showing
**Symptoms:** Plain colors instead of gradients

**Solution:**
1. Check if you're using `Container` with `decoration`
2. Verify `LinearGradient` is properly defined
3. Restart app with hot restart (R)
4. Clear build cache: `flutter clean`

#### Issue: Animations not working
**Symptoms:** No smooth transitions

**Solution:**
1. Check if `flutter_animate` package is installed
2. Verify `.animate()` is called on widgets
3. Hot restart the app (not just hot reload)
4. Check for console errors
5. Ensure animations are not disabled in developer options

#### Issue: Text overflow errors
**Symptoms:** Yellow/black stripes, overflow warnings

**Solution:**
1. Wrap text in `Flexible` or `Expanded`
2. Add `overflow: TextOverflow.ellipsis`
3. Use `maxLines` parameter
4. Check responsive layouts

#### Issue: Bottom navigation obscured by keyboard
**Symptoms:** Can't see bottom nav when keyboard is open

**Solution:**
1. Add `resizeToAvoidBottomInset: false` to Scaffold
2. Use `SingleChildScrollView` in forms
3. This is expected behavior in some cases

---

### 🏃 Performance Issues

#### Issue: App is slow or laggy
**Symptoms:** Stuttering animations, slow response

**Solution:**
1. Build in release mode: `flutter run --release`
2. Avoid rebuilding entire tree unnecessarily
3. Use `const` constructors where possible
4. Profile with DevTools: `flutter run --profile`
5. Check for infinite loops in StreamBuilder

#### Issue: App size is too large
**Symptoms:** APK is very large

**Solution:**
1. Build with split APKs:
   ```bash
   flutter build apk --split-per-abi
   ```
2. Use App Bundle for Play Store:
   ```bash
   flutter build appbundle
   ```
3. Remove unused assets
4. Enable code shrinking

---

### 🔄 State Management Issues

#### Issue: State not updating
**Symptoms:** UI doesn't reflect data changes

**Solution:**
1. Check if BLoC is properly provided
2. Verify events are being added correctly
3. Check if state is being emitted
4. Use `BlocBuilder` or `BlocConsumer` properly
5. Don't forget to add new states to switch cases

#### Issue: Multiple rebuilds
**Symptoms:** Console shows many rebuild messages

**Solution:**
1. Use `const` constructors
2. Move widgets to separate classes
3. Use `Equatable` for state comparison
4. Profile with performance overlay

---

### 🌐 Network Issues

#### Issue: "No internet connection" errors
**Symptoms:** Can't load data from Firebase

**Solution:**
1. Check device internet connection
2. Try on different network (WiFi/Mobile data)
3. Check Firebase service status
4. Verify API keys are correct
5. Check firewall/proxy settings

#### Issue: Slow data loading
**Symptoms:** Long wait times for data

**Solution:**
1. Optimize Firestore queries
2. Limit data fetched with `.limit()`
3. Use pagination
4. Cache data locally
5. Check network speed

---

### 📦 Package/Dependency Issues

#### Issue: Version conflicts
**Symptoms:** Pub get fails with version error

**Solution:**
1. Check compatible versions in `pubspec.yaml`
2. Update all packages: `flutter pub upgrade`
3. Check package compatibility
4. Remove version constraints temporarily
5. Use `flutter pub outdated` to check updates

#### Issue: "Package not found" error
**Symptoms:** Import statements show errors

**Solution:**
1. Run `flutter pub get`
2. Check spelling in `pubspec.yaml`
3. Verify package exists on pub.dev
4. Check internet connection
5. Clear pub cache: `flutter pub cache repair`

---

### 🧪 Testing Issues

#### Issue: Can't add sample data as admin
**Symptoms:** Admin features not accessible

**Solution:**
1. Check if logged in as admin
2. Verify role in Firestore:
   - Go to users collection
   - Find your user document
   - Set `role: "admin"` (must be lowercase)
3. Logout and login again
4. Check admin panel shows in bottom navigation

#### Issue: Match scheduling fails
**Symptoms:** Can't create matches

**Solution:**
1. Ensure sports are added first
2. Create at least 2 teams
3. Select different teams (not the same team twice)
4. Check all required fields are filled
5. Choose a future date

---

### 🔍 Debug Tips

#### Enable Verbose Logging
```bash
flutter run --verbose
```

#### Check Flutter Doctor
```bash
flutter doctor -v
```

#### View Logs
```bash
# Android
adb logcat | grep flutter

# iOS (macOS)
xcrun simctl spawn booted log stream --predicate 'processImagePath endswith "Runner"'
```

#### Clear Everything
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock  # macOS only
flutter pub get
```

---

## 📞 Getting Help

If issues persist:

1. **Check Documentation**
   - README.md
   - FIREBASE_SETUP.md
   - This troubleshooting guide

2. **Check Console Output**
   - Read error messages carefully
   - Look for stack traces
   - Note line numbers

3. **Firebase Console**
   - Check Authentication users
   - Verify Firestore data
   - Review security rules
   - Check service status

4. **Flutter Community**
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
   - [Flutter Discord](https://discord.gg/flutter)
   - [Flutter GitHub](https://github.com/flutter/flutter/issues)

5. **Firebase Support**
   - [Firebase Documentation](https://firebase.google.com/docs)
   - [Firebase Support](https://firebase.google.com/support)

---

## ✅ Prevention Tips

1. **Always run `flutter pub get` after changing `pubspec.yaml`**
2. **Keep Flutter SDK updated: `flutter upgrade`**
3. **Use version control (Git)**
4. **Test on real devices, not just emulators**
5. **Keep Firebase packages updated**
6. **Backup Firestore data regularly**
7. **Use proper error handling in code**
8. **Test with different network conditions**
9. **Monitor Firebase usage and quotas**
10. **Keep good documentation of custom changes**

---

## 🚨 Emergency Reset

If nothing works, complete reset:

```bash
# Save your work first!
# git commit -am "backup before reset"

# Delete generated files
flutter clean
rm -rf build/
rm -rf .dart_tool/

# iOS (macOS only)
cd ios
rm -rf Pods Podfile.lock .symlinks
pod cache clean --all
cd ..

# Reinstall everything
flutter pub get

# iOS (macOS only)
cd ios
pod install
cd ..

# Try running
flutter run
```

---

**Still having issues? Create an issue in the repository with:**
- Error message (full text)
- Steps to reproduce
- Flutter doctor output
- Platform (Android/iOS)
- Device/Emulator details

---

**Most issues are resolved with a simple `flutter clean` and `flutter pub get`! 🎯**
