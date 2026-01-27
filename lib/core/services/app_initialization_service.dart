import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/sport_config_repository.dart';

class AppInitializationService {
  final SportConfigRepository _sportConfigRepository;

  AppInitializationService(this._sportConfigRepository);

  /// Initialize app on first run
  Future<void> initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('is_first_run') ?? true;

      if (isFirstRun) {
        print('🚀 First run detected. Initializing default sports...');
        await _sportConfigRepository.initializeDefaultSports();
        await prefs.setBool('is_first_run', false);
        print('✅ App initialization complete');
      } else {
        // Check if default sports exist, if not initialize them
        final hasDefaultSports = await _sportConfigRepository.areDefaultSportsInitialized();
        if (!hasDefaultSports) {
          print('⚠️ Default sports missing. Re-initializing...');
          await _sportConfigRepository.initializeDefaultSports();
        }
      }
    } catch (e) {
      print('❌ Error initializing app: $e');
      // Don't rethrow - app should continue even if initialization fails
    }
  }

  /// Reset app to factory settings
  Future<void> resetApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_run', true);
      await _sportConfigRepository.resetDefaultSports();
      print('✅ App reset to factory settings');
    } catch (e) {
      print('❌ Error resetting app: $e');
      rethrow;
    }
  }
}
