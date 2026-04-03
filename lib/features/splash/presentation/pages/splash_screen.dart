import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to main screen after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
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
                
                // Startup loader
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .fadeIn(
                                  duration: const Duration(milliseconds: 450),
                                  delay: Duration(milliseconds: index * 180),
                                )
                                .scale(
                                  begin: const Offset(0.6, 0.6),
                                  end: const Offset(1.25, 1.25),
                                  duration: const Duration(milliseconds: 450),
                                  delay: Duration(milliseconds: index * 180),
                                ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Loading your sports hub...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.2,
                          ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 700)),
              ],
            ),
          ),
        ),
    );
  }
}
