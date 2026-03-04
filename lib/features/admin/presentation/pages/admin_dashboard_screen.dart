import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_dashboard_card.dart';
import '../../../home/presentation/pages/standings_screen.dart';
import 'manage_sports_screen.dart';
import 'manage_teams_screen.dart';
import 'manage_matches_screen.dart';
import 'manage_institutes_screen.dart';
import 'manage_tournaments_screen.dart';
import 'cricket_match_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitializing = false;

  Future<void> _initializeDefaultSports() async {
    setState(() => _isInitializing = true);

    try {
      final sportsSnapshot = await _firestore.collection('sports').get();
      
      if (sportsSnapshot.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sports already exist in database!'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isInitializing = false);
        return;
      }

      // Default sports list
      final defaultSports = [
        {'name': 'Cricket', 'icon': '🏏', 'description': 'Cricket matches', 'numberOfPlayers': 11},
        {'name': 'Football', 'icon': '⚽', 'description': 'Football matches', 'numberOfPlayers': 11},
        {'name': 'Basketball', 'icon': '🏀', 'description': 'Basketball matches', 'numberOfPlayers': 5},
        {'name': 'Badminton', 'icon': '🏸', 'description': 'Badminton matches', 'numberOfPlayers': 2},
        {'name': 'Volleyball', 'icon': '🏐', 'description': 'Volleyball matches', 'numberOfPlayers': 6},
        {'name': 'Table Tennis', 'icon': '🏓', 'description': 'Table Tennis matches', 'numberOfPlayers': 2},
        {'name': 'Tennis', 'icon': '🎾', 'description': 'Tennis matches', 'numberOfPlayers': 2},
        {'name': 'Tug of War', 'icon': '🪢', 'description': 'Tug of War matches', 'numberOfPlayers': 8},
        {'name': 'Kabaddi', 'icon': '🤼', 'description': 'Kabaddi matches', 'numberOfPlayers': 7},
        {'name': 'Athletics', 'icon': '🏃', 'description': 'Athletics events', 'numberOfPlayers': 1},
        {'name': 'Swimming', 'icon': '🏊', 'description': 'Swimming events', 'numberOfPlayers': 1},
        {'name': 'Chess', 'icon': '♟️', 'description': 'Chess matches', 'numberOfPlayers': 2},
        {'name': 'Carrom', 'icon': '🎯', 'description': 'Carrom matches', 'numberOfPlayers': 2},
        {'name': 'Frisbee', 'icon': '🥏', 'description': 'Frisbee matches', 'numberOfPlayers': 7},
      ];

      // Add each sport to Firestore
      final batch = _firestore.batch();
      for (final sport in defaultSports) {
        final docRef = _firestore.collection('sports').doc();
        batch.set(docRef, {
          'id': docRef.id,
          'name': sport['name'],
          'icon': sport['icon'],
          'description': sport['description'],
          'numberOfPlayers': sport['numberOfPlayers'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Added ${defaultSports.length} default sports!'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: AppTheme.getBackgroundDecoration(context),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Admin Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Quick Stats
                      FutureBuilder<List<QuerySnapshot>>(
                        future: Future.wait([
                          _firestore.collection('sports').get(),
                          _firestore.collection('teams').get(),
                          _firestore.collection('matches').get(),
                          _firestore.collection('institutes').get(),
                        ]),
                        builder: (context, snapshot) {
                          int sportsCount = 0;
                          int teamsCount = 0;
                          int matchesCount = 0;
                          int institutesCount = 0;

                          if (snapshot.hasData && snapshot.data!.length == 4) {
                            sportsCount = snapshot.data![0].docs.length;
                            teamsCount = snapshot.data![1].docs.length;
                            matchesCount = snapshot.data![2].docs.length;
                            institutesCount = snapshot.data![3].docs.length;
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      Icons.sports,
                                      'Sports',
                                      sportsCount.toString(),
                                      AppTheme.primaryGradient,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      Icons.groups,
                                      'Teams',
                                      teamsCount.toString(),
                                      AppTheme.accentGradient,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      Icons.event,
                                      'Matches',
                                      matchesCount.toString(),
                                      AppTheme.successGradient,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      Icons.school,
                                      'Institutes',
                                      institutesCount.toString(),
                                      const LinearGradient(
                                        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Initialize Default Sports Button (show only if no sports)
                              if (sportsCount == 0) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10b981), Color(0xFF059669)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.sports, color: Colors.white, size: 32),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'No Sports Found',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _isInitializing ? null : _initializeDefaultSports,
                                        icon: _isInitializing
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.add_circle),
                                        label: Text(_isInitializing ? 'Adding...' : 'Add Default Sports'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF10b981),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
                        },
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'Management',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 16),

                      // Management Cards
                      AdminDashboardCard(
                        icon: Icons.sports_soccer,
                        title: 'Manage Sports',
                        subtitle: 'Add, edit, or remove sports categories',
                        gradient: AppTheme.primaryGradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageSportsScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),

                      AdminDashboardCard(
                        icon: Icons.school,
                        title: 'Manage Institutes',
                        subtitle: 'Add university departments & institutes',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageInstitutesScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),

                      AdminDashboardCard(
                        icon: Icons.groups,
                        title: 'Manage Teams',
                        subtitle: 'Add, edit, or remove teams',
                        gradient: AppTheme.accentGradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageTeamsScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),

                      AdminDashboardCard(
                        icon: Icons.event,
                        title: 'Manage Matches',
                        subtitle: 'Schedule matches and update results',
                        gradient: AppTheme.successGradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageMatchesScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),

                      AdminDashboardCard(
                        icon: Icons.emoji_events,
                        title: 'Manage Standings',
                        subtitle: 'Update points table and rankings',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StandingsScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),
                      AdminDashboardCard(
                        icon: Icons.sports_cricket,
                        title: 'Cricket Scoring',
                        subtitle: 'Live cricket match scoring & statistics',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10b981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CricketMatchListScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),
                      AdminDashboardCard(
                        icon: Icons.workspace_premium,
                        title: 'Tournaments',
                        subtitle: 'Create & manage tournaments with auto fixtures',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFe11d48), Color(0xFFbe123c)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageTournamentsScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Gradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
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
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
