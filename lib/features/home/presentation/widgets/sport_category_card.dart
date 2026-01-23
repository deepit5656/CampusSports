import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/sport_model.dart';
import '../pages/sport_detail_screen.dart';

class SportCategoryCard extends StatelessWidget {
  final SportModel sport;

  const SportCategoryCard({super.key, required this.sport});

  IconData _getSportIcon(String sportName) {
    final name = sportName.toLowerCase();
    if (name.contains('cricket')) return Icons.sports_cricket;
    if (name.contains('football') || name.contains('soccer')) {
      return Icons.sports_soccer;
    }
    if (name.contains('basketball')) return Icons.sports_basketball;
    if (name.contains('volleyball')) return Icons.sports_volleyball;
    if (name.contains('tennis')) return Icons.sports_tennis;
    if (name.contains('badminton')) return Icons.sports_tennis;
    return Icons.sports;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SportDetailScreen(sport: sport),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGradientStart.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                _getSportIcon(sport.name),
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getSportIcon(sport.name),
                    size: 28,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sport.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View matches',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
