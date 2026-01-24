# CampusSports 🏆

A modern Flutter application for managing and displaying university sports event information with real-time updates and comprehensive admin features.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)

## 🌟 Features

### Public Access (No Login Required)
- Browse all sports categories and matches
- View live match scores and schedules
- Check team standings and rankings
- Real-time data synchronization

### Admin Features (Login Required)
- Manage sports categories
- Create and manage teams
- Schedule matches and update results
- Maintain standings and points tables

## 🛠️ Tech Stack

- **Framework:** Flutter 3.0+
- **State Management:** flutter_bloc
- **Backend:** Firebase (Auth, Firestore, Storage)
- **UI:** Custom gradients, animations, dark theme

## 🏗️ Architecture

Clean Architecture with BLoC pattern:

```
lib/
├── core/
│   ├── models/          # Data models
│   ├── theme/           # App theme
│   └── utils/           # Utilities
├── features/
│   ├── auth/            # Authentication
│   │   ├── data/        # Repositories
│   │   └── presentation/ # BLoC & UI
│   ├── home/            # User screens
│   ├── admin/           # Admin panel
│   ├── auth/            # Authentication
│   ├── home/            # Home screen
│   └── splash/          # Splash screen
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart SDK 3.0+ (comes with Flutter)
- Android Studio or VS Code with Flutter extension
- Git

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/deepit5656/CampusSports.git
   cd CampusSports
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**
   ```bash
   flutter doctor
   ```
   Fix any issues reported before proceeding.

4. **Run the app**
   
   For Android:
   ```bash
   flutter run
   ```
   
   For Chrome (Web):
   ```bash
   flutter run -d chrome
   ```

**Note:** The project already includes Firebase configuration files (`google-services.json` and `firebase_options.dart`), so Firebase is ready to use out of the box!

### Admin Access

To test admin features:
1. Run the app and go to Profile tab
2. Sign up with any email/password
3. Contact the repository owner to upgrade your account to admin role

### Troubleshooting

- **Build errors**: Run `flutter clean` then `flutter pub get`
- **Firebase errors**: Ensure you're connected to the internet
- **Gradle errors**: Check your internet connection and try again

## 📱 Screenshots

_Coming soon_

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

**deepit5656**
- GitHub: [@deepit5656](https://github.com/deepit5656)
- `intl: ^0.19.0` - Date formatting
- `google_fonts: ^6.1.0` - Custom fonts
- `image_picker: ^1.0.7` - Image selection
- `share_plus: ^7.2.1` - Share functionality

## 🗄️ Firestore Collections

### Users
```json
{
  "id": "string",
  "email": "string",
  "name": "string",
  "role": "admin|user",
  "createdAt": "timestamp"
}
```

### Sports
```json
{
  "id": "string",
  "name": "string",
  "icon": "string",
  "description": "string",
  "createdAt": "timestamp"
}
```

### Teams
```json
{
  "id": "string",
  "name": "string",
  "department": "string",
  "logo": "string",
  "players": ["string"],
  "createdAt": "timestamp"
}
```

### Matches
```json
{
  "id": "string",
  "sportId": "string",
  "team1Id": "string",
  "team2Id": "string",
  "dateTime": "timestamp",
  "venue": "string",
  "status": "upcoming|live|completed|cancelled",
  "score": {
    "team1Id": "number",
    "team2Id": "number"
  },
  "winnerId": "string",
  "createdAt": "timestamp"
}
```

### Standings
```json
{
  "id": "string",
  "sportId": "string",
  "teamId": "string",
  "played": "number",
  "won": "number",
  "lost": "number",
  "drawn": "number",
  "points": "number",
  "goalsFor": "number",
  "goalsAgainst": "number",
  "updatedAt": "timestamp"
}
```

## 🎨 Color Scheme

```dart
Primary Gradient: #667eea → #764ba2 (Purple-Blue)
Accent Gradient: #f093fb → #f5576c (Pink-Red)
Success: #4ade80
Warning: #fbbf24
Error: #ef4444
Background Dark: #0f172a
Card Dark: #1e293b
Surface Dark: #334155
Text: #f8fafc
Text Secondary: #94a3b8
```

## 👥 Access Model

### 🌐 Public Access (No Authentication)
- ✅ View all sports categories
- ✅ Browse match schedules
- ✅ Check team standings  
- ✅ View match details and results
- ✅ Real-time score updates
- ❌ No login or account creation needed

### 🔐 Admin Access (Authentication Required)
- ✅ All public access features
- ✅ Full CRUD operations on sports, teams, and matches
- ✅ Update match results and standings
- ✅ Access to admin dashboard
- ✅ Secure Firebase authentication
- 🔑 Login required via Profile tab

## 🔒 Security

The app uses **Firestore Security Rules** to ensure:
- Public read access for sports data
- Admin-only write access for data management
- User data privacy protection

See [FIRESTORE_RULES.md](FIRESTORE_RULES.md) for detailed security configuration.

## 🧪 Testing

### Creating Admin Account

1. **Sign up** through the app
2. Go to **Firebase Console** → Firestore → users collection
3. Find your user document
4. Set `role` field to `"admin"` (lowercase)
5. **Logout and login** to see admin features

### Test Data

Add sample data using admin panel or see [SAMPLE_DATA.md](SAMPLE_DATA.md) for examples.

## � Screenshots

_Coming soon_

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

**deepit5656**
- GitHub: [@deepit5656](https://github.com/deepit5656)

---

**Made with Flutter 💙**
