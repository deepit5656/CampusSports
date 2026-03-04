import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/main_screen.dart';
import '../../../auth/presentation/pages/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate based on auth state after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => user != null
                ? const MainScreen()
                : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    size: 70,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(),
                
                const SizedBox(height: 30),
                
                // App Name
                Text(
                  'Sports Event',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 300))
                    .slideY(begin: 0.3, end: 0),
                
                Text(
                  'Manager',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 500))
                    .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 50),
                
                // Loading Indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(delay: const Duration(milliseconds: 700)),
              ],
            ),
          ),
        ),
    );
  }
}
