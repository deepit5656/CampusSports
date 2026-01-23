# Sports Event Manager - Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### Step 1: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 2: Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add Android/iOS apps
4. Download config files:
   - `google-services.json` → Place in `android/app/`
   - `GoogleService-Info.plist` → Place in `ios/Runner/`

### Step 3: Enable Firebase Services
In Firebase Console:
1. **Authentication** → Enable Email/Password
2. **Firestore Database** → Create database (Test mode)

### Step 4: Run the App
```bash
flutter run
```

## 📝 First Time Usage

### 1. Create Admin Account
- Open the app
- Click "Sign Up"
- Fill in details
- Select **Admin** role
- Sign up

### 2. Add Sports Categories
- Go to Admin Dashboard
- Tap "Manage Sports"
- Add sports (e.g., Football, Cricket, Basketball)

### 3. Add Teams
- Go to "Manage Teams"
- Add at least 2 teams per sport
- Include team name and department

### 4. Schedule Matches
- Go to "Manage Matches"
- Select sport and teams
- Set date, time, and venue
- Schedule match

### 5. Update Results (After Match)
- In "Manage Matches"
- Tap "Update Result" on a match
- Enter scores
- Change status to "Completed"

## 🎯 Key Features to Try

### For Users:
- Browse sports categories on home screen
- View match schedules
- Check standings/points table
- View detailed match information

### For Admins:
- Access admin panel from bottom navigation
- Manage all sports data
- Update match results in real-time
- View quick statistics

## 🔧 Troubleshooting

**Issue: Firebase errors**
- Solution: Make sure config files are in correct locations
- Run: `flutter clean && flutter pub get`

**Issue: Can't see data**
- Solution: Check Firestore rules are set correctly
- Make sure you're logged in

**Issue: Build errors**
- Solution: Check Flutter/Dart versions
- Run: `flutter doctor`

## 📱 Testing Credentials

After creating accounts, you can use:
- Admin: Your created admin account
- User: Create a separate user account

## 🎨 Customization

### Change Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color primaryGradientStart = Color(0xFF667eea); // Change this
static const Color primaryGradientEnd = Color(0xFF764ba2);   // Change this
```

### Change App Name
Edit `pubspec.yaml`:
```yaml
name: your_app_name
```

## 📚 Next Steps

1. Read full [README.md](README.md) for detailed documentation
2. Check [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for advanced Firebase configuration
3. Explore the code structure in `lib/` directory
4. Customize the theme and colors to match your brand

## 💡 Tips

- **Test with sample data**: Add 3-4 sports, 6-8 teams, and schedule 10+ matches
- **Role testing**: Create both admin and user accounts to test all features
- **Responsive design**: App works on all screen sizes
- **Pull to refresh**: Swipe down on lists to refresh data

## 🆘 Need Help?

- Check the detailed README.md
- Review Firebase setup documentation
- Ensure all dependencies are installed
- Verify Firebase configuration

---

**Happy coding! 🎉**
