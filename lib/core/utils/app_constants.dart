class AppConstants {
  // App Info
  static const String appName = 'Sports Event Manager';
  static const String appVersion = '1.0.0';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  
  // Match Status
  static const String matchStatusUpcoming = 'upcoming';
  static const String matchStatusLive = 'live';
  static const String matchStatusCompleted = 'completed';
  static const String matchStatusCancelled = 'cancelled';
  
  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionSports = 'sports';
  static const String collectionTeams = 'teams';
  static const String collectionMatches = 'matches';
  static const String collectionStandings = 'standings';
  static const String collectionTournaments = 'tournaments';
  
  // SharedPreferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';
  static const String keyIsLoggedIn = 'is_logged_in';
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorPermission = 'You don\'t have permission to perform this action.';
  
  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successSignup = 'Account created successfully!';
  static const String successDataSaved = 'Data saved successfully!';
  static const String successDataDeleted = 'Data deleted successfully!';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
}
