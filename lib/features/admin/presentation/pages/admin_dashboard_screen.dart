import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_dashboard_card.dart';
import '../../../home/presentation/pages/standings_screen.dart';
import 'manage_sports_screen.dart';
import 'manage_teams_screen.dart';
import 'manage_matches_screen.dart';
import 'cricket_match_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
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
                          firestore.collection('sports').get(),
                          firestore.collection('teams').get(),
                          firestore.collection('matches').get(),
                        ]),
                        builder: (context, snapshot) {
                          int sportsCount = 0;
                          int teamsCount = 0;
                          int matchesCount = 0;

                          if (snapshot.hasData && snapshot.data!.length == 3) {
                            sportsCount = snapshot.data![0].docs.length;
                            teamsCount = snapshot.data![1].docs.length;
                            matchesCount = snapshot.data![2].docs.length;
                          }

                          return Row(
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
