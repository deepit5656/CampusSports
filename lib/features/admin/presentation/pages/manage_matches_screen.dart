import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/default_sport_configurations_comprehensive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/services/standings_service.dart';
import 'cricket/cricket_match_control_screen.dart';
import 'football/football_match_control_screen.dart';
import 'basketball/basketball_match_control_screen.dart';
import 'badminton/badminton_match_control_screen.dart';
import 'table_tennis/table_tennis_match_control_screen.dart';
import 'volleyball/volleyball_match_control_screen.dart';
import 'tennis/tennis_match_control_screen.dart';
import 'kabaddi/kabaddi_match_control_screen.dart';
import 'tugofwar/tugofwar_match_control_screen.dart';
import 'frisbee/frisbee_match_control_screen.dart';

class ManageMatchesScreen extends StatefulWidget {
  const ManageMatchesScreen({super.key});

  @override
  State<ManageMatchesScreen> createState() => _ManageMatchesScreenState();
}

class _ManageMatchesScreenState extends State<ManageMatchesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedSportId;
  String _selectedStatus = 'all'; // all, upcoming, live, completed
  TabController? _tabController;
  List<SportModel> _sports = [];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }



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
                  gradient: AppTheme.successGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Title and back button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Manage Matches',
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
                    // Sport Tabs
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('sports').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        _sports = snapshot.data!.docs
                            .map((doc) => SportModel.fromSnapshot(doc))
                            .where((sport) => sport.name.isNotEmpty) // Filter out blank sports
                            .toList();
                        
                        // Sort sports alphabetically to ensure consistent display
                        _sports.sort((a, b) => a.name.compareTo(b.name));

                        if (_tabController == null || _tabController!.length != _sports.length + 1) {
                          _tabController?.dispose();
                          _tabController = TabController(
                            length: _sports.length + 1,
                            vsync: this,
                          );
                          _tabController!.addListener(() {
                            if (!_tabController!.indexIsChanging) {
                              setState(() {
                                _selectedSportId = _tabController!.index == 0
                                    ? null
                                    : _sports[_tabController!.index - 1].id;
                              });
                            }
                          });
                        }

                        return Container(
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            indicatorColor: Colors.white,
                            indicatorWeight: 3,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              const Tab(text: 'All Sports'),
                              ..._sports.map((sport) => Tab(text: sport.name)),
                            ],
                          ),
                        );
                      },
                    ),

                    // Status Filters
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Upcoming', 'upcoming'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Live', 'live'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Finished', 'completed'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Matches List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('matches')
                      .orderBy('dateTime', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var matches = snapshot.data!.docs
                        .map((doc) => MatchModel.fromSnapshot(doc))
                        .toList();

                    // Filter by sport
                    if (_selectedSportId != null) {
                      matches = matches.where((m) => m.sportId == _selectedSportId).toList();
                    }

                    // Filter by status
                    if (_selectedStatus != 'all') {
                      matches = matches.where((m) => m.status == _selectedStatus).toList();
                    }

                    if (matches.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedStatus == 'all' 
                                  ? 'No matches scheduled yet' 
                                  : 'No ${_selectedStatus} matches',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to schedule your first match',
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
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return _buildMatchCard(match, index)
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
        onPressed: () => _showAddMatchDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Match'),
        backgroundColor: AppTheme.successColor,
      ).animate().scale(delay: 200.ms),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      backgroundColor: Colors.white.withOpacity(0.1),
      selectedColor: Colors.white.withOpacity(0.3),
      labelStyle: TextStyle(
        color: Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildMatchCard(MatchModel match, int index) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('sports').doc(match.sportId).get(),
      builder: (context, sportSnapshot) {
        final sport = sportSnapshot.hasData ? SportModel.fromSnapshot(sportSnapshot.data!) : null;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status, Sport and Date Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(match.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      match.status.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(match.status),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (sport != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGradientStart.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sport.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryGradientStart,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(match.dateTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Teams with Scores and Roster Status
              FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  _getTeam(match.team1Id),
                  _getTeam(match.team2Id),
                  _isTeamRosterComplete(match.team1Id, match.sportId),
                  _isTeamRosterComplete(match.team2Id, match.sportId),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final team1 = snapshot.data![0] as TeamModel?;
                  final team2 = snapshot.data![1] as TeamModel?;
                  final team1Complete = snapshot.data![2] as bool;
                  final team2Complete = snapshot.data![3] as bool;
                  final score1 = match.score?[match.team1Id];
                  final score2 = match.score?[match.team2Id];
                  final hasScores = score1 != null || score2 != null;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    team1?.name ?? 'Unknown',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: match.winnerId == match.team1Id 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                      color: match.winnerId == match.team1Id
                                        ? AppTheme.successColor
                                        : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasScores) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: match.winnerId == match.team1Id
                                  ? AppTheme.successColor.withOpacity(0.2)
                                  : AppTheme.backgroundDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: match.winnerId == match.team1Id
                                    ? AppTheme.successColor
                                    : Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                score1?.toString() ?? '0',
                                style: TextStyle(
                                  color: match.winnerId == match.team1Id
                                    ? AppTheme.successColor
                                    : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    team2?.name ?? 'Unknown',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: match.winnerId == match.team2Id 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                      color: match.winnerId == match.team2Id
                                        ? AppTheme.successColor
                                        : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasScores) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: match.winnerId == match.team2Id
                                  ? AppTheme.successColor.withOpacity(0.2)
                                  : AppTheme.backgroundDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: match.winnerId == match.team2Id
                                    ? AppTheme.successColor
                                    : Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                score2?.toString() ?? '0',
                                style: TextStyle(
                                  color: match.winnerId == match.team2Id
                                    ? AppTheme.successColor
                                    : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!hasScores) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppTheme.successGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'VS',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              // Venue
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    match.venue,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (match.isUpcoming || match.isLive)
                    TextButton.icon(
                      onPressed: () {
                        if (sport != null) {
                          _navigateToMatchControl(context, match, sport);
                        }
                      },
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: Text(sport?.name.toLowerCase() == 'cricket' ? 'Manage Match' : 'Update Result'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.successColor,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                    onPressed: () => _showDeleteDialog(context, match),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToMatchControl(BuildContext context, MatchModel match, SportModel sport) {
    final sportName = sport.name.toLowerCase();
    
    if (sportName == 'cricket') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CricketMatchControlScreen(
            matchId: match.id,
          ),
        ),
      );
    } else if (sportName == 'football') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FootballMatchControlScreen(
            matchId: match.id,
          ),
        ),
      );
    } else if (sportName == 'basketball') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BasketballMatchControlScreen(
            matchId: match.id,
          ),
        ),
      );
    } else if (sportName == 'badminton') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BadmintonMatchControlScreen(
            match: match,
          ),
        ),
      );
    } else if (sportName == 'table tennis' || sportName == 'tabletennis') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TableTennisMatchControlScreen(
            match: match,
          ),
        ),
      );
    } else if (sportName == 'volleyball') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VolleyballMatchControlScreen(
            match: match,
          ),
        ),
      );
    } else if (sportName == 'tennis') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TennisMatchControlScreen(
            match: match,
          ),
        ),
      );
    } else if (sportName == 'kabaddi') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KabaddiMatchControlScreen(
            match: match,
          ),
        ),
      );
    } else if (sportName == 'tug of war' || sportName == 'tugofwar') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TugOfWarMatchControlScreen(
            match: match,
          ),
        ),
      );
    } else if (sportName == 'frisbee') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FrisbeeMatchControlScreen(
            match: match,
          ),
        ),
      );
    } else {
      // Default: show simple update dialog for other sports (Athletics, Swimming, Chess, Carrom)
      _showUpdateResultDialog(context, match);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return AppTheme.accentGradientStart;
      case 'live':
        return AppTheme.successColor;
      case 'completed':
        return AppTheme.textSecondary;
      default:
        return AppTheme.errorColor;
    }
  }

  Future<void> _showAddMatchDialog(BuildContext context) async {
    final sports = await _firestore.collection('sports').get();
    final allTeams = await _firestore.collection('teams').get();
    final players = await _firestore.collection('players').get();

    if (sports.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add sports first!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    String? selectedSportId = sports.docs.first.id;
    String? selectedTeam1Id;
    String? selectedTeam2Id;
    String selectedCategory = 'Boys';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final venueController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    // Helper function to get eligible teams for selected sport
    List<TeamModel> getEligibleTeams(String? sportId) {
      if (sportId == null) return [];
      
      try {
        // Simply return all teams that have players
        // Don't filter by numberOfPlayers if it's not set or problematic
        final teamsWithPlayers = allTeams.docs
            .map((doc) => TeamModel.fromSnapshot(doc))
            .where((team) {
          // Check if team has at least some players
          final teamPlayerCount = players.docs
              .where((playerDoc) {
                final playerData = playerDoc.data() as Map<String, dynamic>?;
                return playerData != null && playerData['teamId'] == team.id;
              })
              .length;
          return teamPlayerCount > 0; // At least 1 player required
        }).toList();
        
        return teamsWithPlayers.isNotEmpty 
            ? teamsWithPlayers 
            : allTeams.docs.map((doc) => TeamModel.fromSnapshot(doc)).toList();
      } catch (e) {
        print('Error getting eligible teams: $e');
        // Fallback: return all teams
        return allTeams.docs.map((doc) => TeamModel.fromSnapshot(doc)).toList();
      }
    }

    // Initialize with eligible teams
    var eligibleTeams = getEligibleTeams(selectedSportId);
    if (eligibleTeams.isNotEmpty) {
      selectedTeam1Id = eligibleTeams.first.id;
      selectedTeam2Id = eligibleTeams.length > 1 ? eligibleTeams[1].id : eligibleTeams.first.id;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Schedule Match'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sport Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSportId,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      prefixIcon: Icon(Icons.sports),
                    ),
                    items: sports.docs
                        .map((doc) => SportModel.fromSnapshot(doc))
                        .where((sport) => sport.name.isNotEmpty) // Filter out blank sports
                        .map((sport) {
                      return DropdownMenuItem(
                        value: sport.id,
                        child: Text(sport.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSportId = value;
                        // Refresh eligible teams when sport changes
                        eligibleTeams = getEligibleTeams(value);
                        if (eligibleTeams.isNotEmpty) {
                          selectedTeam1Id = eligibleTeams.first.id;
                          selectedTeam2Id = eligibleTeams.length > 1 ? eligibleTeams[1].id : eligibleTeams.first.id;
                        } else {
                          selectedTeam1Id = null;
                          selectedTeam2Id = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Team 1 Dropdown
                  DropdownButtonFormField<String?>(
                    value: eligibleTeams.any((t) => t.id == selectedTeam1Id) ? selectedTeam1Id : null,
                    decoration: const InputDecoration(
                      labelText: 'Team 1',
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: eligibleTeams.isEmpty 
                      ? [DropdownMenuItem<String?>(value: null, child: Text('No eligible teams'))]
                      : eligibleTeams.map((team) {
                          return DropdownMenuItem<String?>(
                            value: team.id,
                            child: Text(team.name),
                          );
                        }).toList(),
                    onChanged: eligibleTeams.isEmpty ? null : (value) {
                      setState(() => selectedTeam1Id = value);
                    },
                    validator: (value) {
                      if (eligibleTeams.isEmpty) {
                        return 'No teams available with complete rosters';
                      }
                      return null;
                    },
                  ),
                  if (eligibleTeams.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Please add teams with complete player rosters for this sport',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Team 2 Dropdown
                  DropdownButtonFormField<String?>(
                    value: eligibleTeams.any((t) => t.id == selectedTeam2Id) ? selectedTeam2Id : null,
                    decoration: const InputDecoration(
                      labelText: 'Team 2',
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: eligibleTeams.isEmpty 
                      ? [DropdownMenuItem<String?>(value: null, child: Text('No eligible teams'))]
                      : eligibleTeams.map((team) {
                          return DropdownMenuItem<String?>(
                            value: team.id,
                            child: Text(team.name),
                          );
                        }).toList(),
                    onChanged: eligibleTeams.isEmpty ? null : (value) {
                      setState(() => selectedTeam2Id = value);
                    },
                    validator: (value) {
                      if (eligibleTeams.isEmpty) {
                        return 'No teams available with complete rosters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ['Boys', 'Girls', 'Faculty'].map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),

                  // Time Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Venue Field
                  TextFormField(
                    controller: venueController,
                    decoration: const InputDecoration(
                      labelText: 'Venue',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Venue'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        if (eligibleTeams.isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Please add teams with complete player rosters first!'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        
                        if (selectedTeam1Id == null || selectedTeam2Id == null) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select both teams!'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        
                        if (selectedTeam1Id == selectedTeam2Id) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select different teams!'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final matchDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          final docRef = _firestore.collection('matches').doc();
                          final newMatch = MatchModel(
                            id: docRef.id,
                            sportId: selectedSportId!,
                            team1Id: selectedTeam1Id!,
                            team2Id: selectedTeam2Id!,
                            dateTime: matchDateTime,
                            venue: venueController.text.trim(),
                            status: 'upcoming',
                            category: selectedCategory,
                            createdAt: DateTime.now(),
                          );
                          await docRef.set(newMatch.toMap());

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Match scheduled successfully!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateResultDialog(BuildContext context, MatchModel match) {
    final team1ScoreController = TextEditingController(
      text: match.score?[match.team1Id]?.toString() ?? '',
    );
    final team2ScoreController = TextEditingController(
      text: match.score?[match.team2Id]?.toString() ?? '',
    );
    String selectedStatus = match.status;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Update Match Result'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                    DropdownMenuItem(value: 'live', child: Text('Live')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Team 1 Score
                TextFormField(
                  controller: team1ScoreController,
                  decoration: const InputDecoration(
                    labelText: 'Team 1 Score',
                    prefixIcon: Icon(Icons.score),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validateNumber(value, 'Score'),
                ),
                const SizedBox(height: 16),

                // Team 2 Score
                TextFormField(
                  controller: team2ScoreController,
                  decoration: const InputDecoration(
                    labelText: 'Team 2 Score',
                    prefixIcon: Icon(Icons.score),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validateNumber(value, 'Score'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        try {
                          final team1Score = int.parse(team1ScoreController.text);
                          final team2Score = int.parse(team2ScoreController.text);
                          
                          String? winnerId;
                          if (selectedStatus == 'completed') {
                            winnerId = team1Score > team2Score 
                                ? match.team1Id 
                                : team2Score > team1Score 
                                    ? match.team2Id 
                                    : null;
                          }

                          await _firestore.collection('matches').doc(match.id).update({
                            'status': selectedStatus,
                            'score': {
                              match.team1Id: team1Score,
                              match.team2Id: team2Score,
                            },
                            'winnerId': winnerId,
                          });

                          // Update standings if match is completed
                          if (selectedStatus == 'completed') {
                            try {
                              final StandingsService standingsService = StandingsService();
                              final updatedMatch = MatchModel(
                                id: match.id,
                                sportId: match.sportId,
                                team1Id: match.team1Id,
                                team2Id: match.team2Id,
                                dateTime: match.dateTime,
                                venue: match.venue,
                                status: 'completed',
                                category: match.category,
                                score: {
                                  match.team1Id: team1Score,
                                  match.team2Id: team2Score,
                                },
                                createdAt: match.createdAt,
                                winnerId: winnerId,
                              );
                              await standingsService.onMatchCompleted(updatedMatch);
                            } catch (e) {
                              print('Error updating standings: $e');
                            }
                          }

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Match updated successfully!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MatchModel match) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Match'),
        content: const Text('Are you sure you want to delete this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('matches').doc(match.id).delete();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Match deleted successfully!'),
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

  Future<TeamModel?> _getTeam(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromSnapshot(doc);
      }
    } catch (e) {
      print('Error fetching team: $e');
    }
    return null;
  }

  Future<bool> _isTeamRosterComplete(String teamId, String sportId) async {
    try {
      // Get sport to find required players
      final sportDoc = await _firestore.collection('sports').doc(sportId).get();
      if (!sportDoc.exists) return false;
      
      final sportData = sportDoc.data() as Map<String, dynamic>;
      final requiredPlayers = sportData['numberOfPlayers'] as int? ?? 0;
      
      // Count players for this team in this sport
      final playersSnapshot = await _firestore
          .collection('players')
          .where('teamId', isEqualTo: teamId)
          .where('sportId', isEqualTo: sportId)
          .get();
      
      return playersSnapshot.docs.length >= requiredPlayers;
    } catch (e) {
      print('Error checking roster: $e');
      return false;
    }
  }
}
