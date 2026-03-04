import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/tournament_model.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/services/tournament_service.dart';

class ManageTournamentsScreen extends StatefulWidget {
  const ManageTournamentsScreen({super.key});

  @override
  State<ManageTournamentsScreen> createState() => _ManageTournamentsScreenState();
}

class _ManageTournamentsScreenState extends State<ManageTournamentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TournamentService _tournamentService = TournamentService();

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
                  gradient: AppTheme.accentGradient,
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
                        'Tournaments',
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

              // Tournament List
              Expanded(
                child: StreamBuilder<List<TournamentModel>>(
                  stream: _tournamentService.getTournaments(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tournaments = snapshot.data!;

                    if (tournaments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text('No tournaments yet',
                                style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            Text('Tap + to create your first tournament',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tournaments.length,
                      itemBuilder: (context, index) {
                        return _buildTournamentCard(tournaments[index], index)
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
        onPressed: () => _showCreateTournamentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
        backgroundColor: AppTheme.accentGradientStart,
      ).animate().scale(delay: 200.ms),
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament, int index) {
    return FutureBuilder(
      future: Future.wait([
        _firestore.collection('sports').doc(tournament.sportId).get(),
        _tournamentService.getTournamentStats(tournament.id),
      ]),
      builder: (context, snapshot) {
        String sportName = 'Loading...';
        Map<String, int> stats = {};

        if (snapshot.hasData) {
          final results = snapshot.data!;
          final sportDoc = results[0] as DocumentSnapshot;
          stats = results[1] as Map<String, int>;
          sportName = sportDoc.exists ? (sportDoc.data() as Map)['name'] ?? 'Unknown' : 'Unknown';
        }

        final statusColor = tournament.status == 'ongoing'
            ? AppTheme.successColor
            : tournament.status == 'completed'
                ? AppTheme.textSecondary
                : AppTheme.accentGradientStart;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.05)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.emoji_events, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$sportName  |  ${tournament.format.name.replaceAll('roundRobin', 'Round Robin').replaceAll('knockout', 'Knockout').replaceAll('groupStage', 'Group Stage')}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tournament.status.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Teams', '${tournament.teamIds.length}', Icons.groups),
                    _statItem('Matches', '${stats['total'] ?? '-'}', Icons.sports_score),
                    _statItem('Completed', '${stats['completed'] ?? '-'}', Icons.check_circle),
                    _statItem(
                        'Date',
                        DateFormat('MMM d').format(tournament.startDate),
                        Icons.calendar_today),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewTournamentMatches(tournament),
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text('Matches'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                      onPressed: () => _confirmDelete(tournament),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  void _viewTournamentMatches(TournamentModel tournament) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events),
                  const SizedBox(width: 8),
                  Text(tournament.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder(
                stream: _tournamentService.getTournamentMatches(tournament.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final matches = snapshot.data!;
                  if (matches.isEmpty) {
                    return const Center(child: Text('No matches generated'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return FutureBuilder(
                        future: Future.wait([
                          _firestore.collection('teams').doc(match.team1Id).get(),
                          _firestore.collection('teams').doc(match.team2Id).get(),
                        ]),
                        builder: (context, teamSnap) {
                          String team1 = 'Team 1';
                          String team2 = 'Team 2';
                          if (teamSnap.hasData) {
                            team1 = (teamSnap.data![0].data() as Map?)?['name'] ?? 'Team 1';
                            team2 = (teamSnap.data![1].data() as Map?)?['name'] ?? 'Team 2';
                          }

                          final statusColor = match.status == 'completed'
                              ? AppTheme.successColor
                              : match.status == 'live'
                                  ? Colors.orange
                                  : AppTheme.textSecondary;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundDark.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$team1  vs  $team2',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${DateFormat('MMM d, h:mm a').format(match.dateTime)}  |  ${match.venue}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (match.score != null && match.score!.isNotEmpty)
                                  Text(
                                    '${match.score![match.team1Id] ?? 0} - ${match.score![match.team2Id] ?? 0}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  )
                                else
                                  Text(match.status.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(TournamentModel tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: const Text('Delete Tournament'),
        content: Text(
            'Delete "${tournament.name}" and all its generated matches? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _tournamentService.deleteTournament(tournament.id);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                      content: Text('Tournament deleted'),
                      backgroundColor: AppTheme.successColor),
                );
              } catch (e) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTournamentDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final venueController = TextEditingController();
    String? selectedSportId;
    TournamentFormat selectedFormat = TournamentFormat.roundRobin;
    List<String> selectedTeamIds = [];
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int groupCount = 2;
    bool isLoading = false;

    // Load sports and teams
    final sportsSnap = await _firestore.collection('sports').get();
    final teamsSnap = await _firestore.collection('teams').get();

    final sports = sportsSnap.docs
        .map((d) => SportModel.fromSnapshot(d))
        .toList();
    final allTeams = teamsSnap.docs
        .map((d) => TeamModel.fromSnapshot(d))
        .toList();

    if (sports.isEmpty || allTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add sports and teams first!'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.getCardColor(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Create Tournament'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tournament Name',
                        prefixIcon: Icon(Icons.emoji_events),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sport
                    DropdownButtonFormField<String>(
                      value: selectedSportId,
                      decoration: const InputDecoration(
                        labelText: 'Sport',
                        prefixIcon: Icon(Icons.sports),
                      ),
                      items: sports
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedSportId = val),
                    ),
                    const SizedBox(height: 16),

                    // Format
                    DropdownButtonFormField<TournamentFormat>(
                      value: selectedFormat,
                      decoration: const InputDecoration(
                        labelText: 'Format',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: TournamentFormat.roundRobin,
                            child: Text('Round Robin')),
                        DropdownMenuItem(
                            value: TournamentFormat.knockout,
                            child: Text('Knockout')),
                        DropdownMenuItem(
                            value: TournamentFormat.groupStage,
                            child: Text('Group Stage')),
                      ],
                      onChanged: (val) => setState(() => selectedFormat = val!),
                    ),
                    const SizedBox(height: 16),

                    if (selectedFormat == TournamentFormat.groupStage) ...[
                      DropdownButtonFormField<int>(
                        value: groupCount,
                        decoration: const InputDecoration(
                          labelText: 'Number of Groups',
                          prefixIcon: Icon(Icons.group_work),
                        ),
                        items: [2, 3, 4]
                            .map((n) => DropdownMenuItem(
                                value: n, child: Text('$n Groups')))
                            .toList(),
                        onChanged: (val) => setState(() => groupCount = val!),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Venue
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(
                        labelText: 'Venue',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Start: ${DateFormat('MMM d, y').format(selectedDate)}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Team selection
                    Text('Select Teams (${selectedTeamIds.length} selected)',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allTeams.length,
                        itemBuilder: (context, index) {
                          final team = allTeams[index];
                          final isSelected = selectedTeamIds.contains(team.id);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(team.name, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(team.department,
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textSecondary)),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedTeamIds.add(team.id);
                                } else {
                                  selectedTeamIds.remove(team.id);
                                }
                              });
                            },
                          );
                        },
                      ),
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
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Enter tournament name')),
                          );
                          return;
                        }
                        if (selectedSportId == null) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Select a sport')),
                          );
                          return;
                        }
                        if (selectedTeamIds.length < 2) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text('Select at least 2 teams')),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final docRef = _firestore.collection('tournaments').doc();
                          final tournament = TournamentModel(
                            id: docRef.id,
                            name: nameController.text.trim(),
                            sportId: selectedSportId!,
                            format: selectedFormat,
                            teamIds: selectedTeamIds,
                            status: 'ongoing',
                            startDate: selectedDate,
                            venue: venueController.text.trim().isNotEmpty
                                ? venueController.text.trim()
                                : null,
                            groupCount: selectedFormat == TournamentFormat.groupStage
                                ? groupCount
                                : null,
                            createdAt: DateTime.now(),
                          );

                          await _tournamentService.createTournament(tournament);

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Tournament created with matches!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
