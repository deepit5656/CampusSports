import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/sport_config_comprehensive.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'sport_teams_screen.dart';

class UniversalSportManagementScreen extends StatefulWidget {
  final String sportId;
  final String sportName;
  final SportConfigModel sportConfig;

  const UniversalSportManagementScreen({
    Key? key,
    required this.sportId,
    required this.sportName,
    required this.sportConfig,
  }) : super(key: key);

  @override
  State<UniversalSportManagementScreen> createState() =>
      _UniversalSportManagementScreenState();
}

class _UniversalSportManagementScreenState
    extends State<UniversalSportManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '${widget.sportName} Management',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryGradientStart,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.successColor,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Teams'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('teams').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final teams = snapshot.data!.docs
            .map((doc) => TeamModel.fromSnapshot(doc))
            .toList();

        if (teams.isEmpty) {
          return _buildEmptyTeamsState();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Teams (${teams.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SportTeamsScreen(
                          sportId: widget.sportId,
                          sportName: widget.sportName,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Manage Players'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGradientStart,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return _buildTeamCard(team);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyTeamsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 24),
          const Text(
            'No Teams Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add teams to start managing ${widget.sportName}',
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SportTeamsScreen(
                  sportId: widget.sportId,
                  sportName: widget.sportName,
                ),
              ),
            ),
            icon: const Icon(Icons.settings),
            label: const Text('Setup Teams'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Text(
        'Match history will appear here',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('sports').doc(widget.sportId).snapshots(),
      builder: (context, sportSnapshot) {
        int numberOfPlayers = 0;
        
        if (sportSnapshot.hasData && sportSnapshot.data != null) {
          try {
            final data = sportSnapshot.data!.data() as Map<String, dynamic>?;
            numberOfPlayers = data?['numberOfPlayers'] as int? ?? 0;
          } catch (e) {
            print('Error getting numberOfPlayers: $e');
            numberOfPlayers = 0;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('players')
              .where('teamId', isEqualTo: team.id)
              .where('sportId', isEqualTo: widget.sportId)
              .snapshots(),
          builder: (context, playersSnapshot) {
            final playerCount =
                playersSnapshot.hasData ? playersSnapshot.data!.docs.length : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppTheme.getCardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          team.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team.department,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (numberOfPlayers > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Players: $playerCount / $numberOfPlayers',
                              style: TextStyle(
                                color: playerCount == numberOfPlayers
                                    ? AppTheme.successColor
                                    : AppTheme.accentGradientStart,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (numberOfPlayers > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: playerCount == numberOfPlayers
                              ? AppTheme.successColor.withOpacity(0.2)
                              : AppTheme.primaryGradientStart.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          playerCount == numberOfPlayers
                              ? 'Complete'
                              : 'Incomplete',
                          style: TextStyle(
                            color: playerCount == numberOfPlayers
                                ? AppTheme.successColor
                                : AppTheme.primaryGradientStart,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
