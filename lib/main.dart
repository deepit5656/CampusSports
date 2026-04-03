import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/app_constants.dart';
import 'core/services/default_sports_service.dart';
import 'core/services/app_initialization_service.dart';
import 'core/repositories/sport_config_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with timeout and error handling
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3));
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed/timed out: $e');
  }
  
  // Initialize default sports with timeout
  try {
    await DefaultSportsService.initializeDefaultSports()
        .timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Default sports initialization skipped/failed: $e');
  }
  
  // Initialize enhanced sport configurations with timeout
  try {
    final sportConfigRepo = SportConfigRepository();
    final appInitService = AppInitializationService(sportConfigRepo);
    await appInitService.initializeApp().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('App initialization skipped/failed: $e');
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0f172a),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(),
          )..add(AuthCheckRequested()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
