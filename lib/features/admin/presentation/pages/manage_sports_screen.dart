import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/sport_config_comprehensive.dart';
import 'sport_configuration_screen.dart';
import 'universal_sport_management_screen.dart';

class ManageSportsScreen extends StatefulWidget {
  const ManageSportsScreen({super.key});

  @override
  State<ManageSportsScreen> createState() => _ManageSportsScreenState();
}

class _ManageSportsScreenState extends State<ManageSportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: AppTheme.getBackgroundDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Manage Sports',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Sports List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('sports').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sports = snapshot.data!.docs
                        .map((doc) => SportConfigModel.fromMap(doc.data() as Map<String, dynamic>))
                        .toList();

                    // Sort sports: default first, then custom
                    sports.sort((a, b) {
                      if (a.isDefault && !b.isDefault) return -1;
                      if (!a.isDefault && b.isDefault) return 1;
                      return a.name.compareTo(b.name);
                    });

                    if (sports.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sports available',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please restart the app to initialize default sports',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sports.length,
                      itemBuilder: (context, index) {
                        final sport = sports[index];
                        return _buildSportCard(sport, index)
                            .animate(delay: (100 * index).ms)
                            .fadeIn()
                            .slideX(begin: -0.2, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSportConfiguration(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Sport'),
        backgroundColor: AppTheme.primaryGradientStart,
      ).animate().scale(delay: 200.ms),
    );
  }

  Widget _buildSportCard(SportConfigModel sport, int index) {
    final icon = _getSportIcon(sport.icon);
    
    return InkWell(
      onTap: () => _navigateToSportManagement(sport),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: sport.isDefault
              ? Border.all(color: AppTheme.primaryGradientStart.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with default sport indicator
            if (sport.isDefault)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Default Sport',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            
            // Sport Card Content
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sport.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sport.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Sport Details Row - Fixed overflow issue
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildInfoChip(
                              sport.getStructureDisplayText(),
                              Icons.access_time,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              '${sport.playingPlayers} Players',
                              Icons.group,
                            ),
                            if (sport.primaryScoreUnit.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                sport.primaryScoreUnit.toUpperCase(),
                                Icons.emoji_events,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons Column
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToSportManagement(sport),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10b981)),
                        ),
                        child: const Text(
                          'Manage',
                          style: TextStyle(
                            color: Color(0xFF10b981),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!sport.isDefault) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.primaryGradientStart),
                            onPressed: () => _navigateToSportConfiguration(context, sport: sport),
                            tooltip: 'Edit Sport',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                            onPressed: () => _showDeleteDialog(context, sport),
                            tooltip: 'Delete Sport',
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                            onPressed: () => _showSportInfoDialog(context, sport),
                            tooltip: 'Sport Info',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGradientStart.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryGradientStart.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryGradientStart),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryGradientStart,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _getSportIcon(String iconString) {
    // Convert emoji string or return default
    switch (iconString) {
      case '🏏': return '🏏';
      case '⚽': return '⚽';
      case '🤼': return '🤼';
      case '🏀': return '🏀';
      case '🤾': return '🤾';
      case '🏐': return '🏐';
      case '🏸': return '🏸';
      case '🏓': return '🏓';
      case '🪢': return '🪢';
      case '🏃': return '🏃';
      case '🥏': return '🥏';
      default: return '⚽';
    }
  }

  void _navigateToSportManagement(SportConfigModel sport) {
    // All sports now use universal management (Teams + History)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversalSportManagementScreen(
          sportId: sport.id,
          sportName: sport.name,
          sportConfig: sport,
        ),
      ),
    );
  }

  void _navigateToSportConfiguration(BuildContext context, {SportConfigModel? sport}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SportConfigurationScreen(
          sportConfig: sport,
          isReadOnly: false,
        ),
      ),
    );
    
    if (result is SportConfigModel) {
      // Sport was created/updated, refresh the list
      setState(() {});
    }
  }

  void _showSportInfoDialog(BuildContext context, SportConfigModel sport) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Text(_getSportIcon(sport.icon), style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(sport.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sport.description),
            const SizedBox(height: 16),
            Text('Match Structure: ${sport.getStructureDisplayText()}'),
            Text('Players: ${sport.playingPlayers}'),
            Text('Scoring Unit: ${sport.primaryScoreUnit}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGradientStart.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: AppTheme.primaryGradientStart, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'This is a default sport template and cannot be modified',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGradientStart,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SportConfigModel sport) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Sport'),
        content: Text('Are you sure you want to delete ${sport.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('sports').doc(sport.id).delete();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sport deleted successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
