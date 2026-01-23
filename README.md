# Sports Event Manager 🏆

A modern Flutter application for managing and displaying university sports event information with a stunning UI, smooth animations, and comprehensive admin features.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)

## 🌟 Key Highlights

- 🌐 **No Login Required** - Browse sports data freely without account
- 🔐 **Admin Login Only** - Secure admin access for data management  
- 📱 **Public Sports Information** - Everyone can view matches, standings, results
- ⚡ **Real-time Updates** - Live score updates via Firebase Firestore

## 📱 Features

### Public Access (No Login)
- 🏠 **Dashboard** - View all sports categories and recent matches
- 🏅 **Sports Categories** - Browse matches by sport
- 📊 **Standings** - View team rankings and points tables
- 🎯 **Match Details** - Detailed match information with scores
- 🔄 **Real-time Updates** - Live match data synchronization

### Admin Features (Login Required)
- ⚽ **Manage Sports** - Add, edit, and delete sports categories
- 👥 **Manage Teams** - Create and manage teams
- 📅 **Manage Matches** - Schedule matches and update results
- 🏆 **Update Standings** - Maintain points tables
- 📊 **Dashboard** - Quick overview of all data

## 🎨 Design Features

- **Modern Dark Theme** - Sleek dark mode UI with vibrant gradients
- **Smooth Animations** - Engaging micro-interactions throughout
- **Responsive Cards** - Beautiful card-based layouts
- **Custom Gradients** - Purple-blue primary, pink-red accent themes
- **Glassmorphism Effects** - Modern blur and transparency effects
- **Hero Animations** - Smooth transitions between screens

## 🏗️ Architecture

The app follows **Clean Architecture** principles with **BLoC** state management:

```
lib/
├── core/
│   ├── models/          # Data models
│   ├── theme/           # App theme and colors
│   └── utils/           # Constants and validators
├── features/
│   ├── auth/            # Authentication
│   │   ├── data/        # Repositories
│   │   └── presentation/ # BLoC & UI
│   ├── home/            # User screens
│   ├── admin/           # Admin panel
│   └── splash/          # Splash screen
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Sports
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Follow the detailed instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core
- `flutter_bloc: ^8.1.3` - State management
- `equatable: ^2.0.5` - Value equality

### Firebase
- `firebase_core: ^2.24.2`
- `firebase_auth: ^4.16.0`
- `cloud_firestore: ^4.14.0`
- `firebase_storage: ^11.6.0`

### UI & Animations
- `flutter_animate: ^4.5.0` - Animations
- `shimmer: ^3.0.0` - Loading effects
- `lottie: ^3.0.0` - Lottie animations
- `cached_network_image: ^3.3.1` - Image caching
- `flutter_svg: ^2.0.9` - SVG support

### Utilities
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

## 📸 Screenshots

[Add screenshots of your app here]

- Splash Screen
- Login/Signup
- Home Dashboard
- Sports Categories
- Match Details
- Standings
- Admin Dashboard
- Manage Sports/Teams/Matches

## 🔮 Future Enhancements

- [ ] Live score updates with real-time listeners
- [ ] Push notifications for match updates
- [ ] Multiple game handlers/scorers
- [ ] Photo gallery for matches
- [ ] Player statistics and profiles
- [ ] Match highlights and commentary
- [ ] Dark/Light theme toggle
- [ ] Tournament bracket visualization
- [ ] Export standings as PDF/Image
- [ ] Social media integration

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

Created with ❤️ using Flutter

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI guidelines
- The Flutter community for packages and support

## 📞 Support

For support, email [your-email@example.com] or create an issue in the repository.

---

**Made with Flutter 💙**
