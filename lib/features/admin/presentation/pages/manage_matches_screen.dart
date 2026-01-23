import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/utils/validators.dart';

class ManageMatchesScreen extends StatefulWidget {
  const ManageMatchesScreen({super.key});

  @override
  State<ManageMatchesScreen> createState() => _ManageMatchesScreenState();
}

class _ManageMatchesScreenState extends State<ManageMatchesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
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

                    final matches = snapshot.data!.docs
                        .map((doc) => MatchModel.fromSnapshot(doc))
                        .toList();

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
                              'No matches scheduled yet',
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

  Widget _buildMatchCard(MatchModel match, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
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
          // Status and Date Row
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
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(match.dateTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Teams
          FutureBuilder<List<TeamModel?>>(
            future: Future.wait([
              _getTeam(match.team1Id),
              _getTeam(match.team2Id),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final team1 = snapshot.data![0];
              final team2 = snapshot.data![1];

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      team1?.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
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
                  Expanded(
                    child: Text(
                      team2?.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.right,
                    ),
                  ),
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
                  onPressed: () => _showUpdateResultDialog(context, match),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Update Result'),
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
    final teams = await _firestore.collection('teams').get();

    if (sports.docs.isEmpty || teams.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add sports and teams first!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    String? selectedSportId = sports.docs.first.id;
    String? selectedTeam1Id = teams.docs.first.id;
    String? selectedTeam2Id = teams.docs.length > 1 ? teams.docs[1].id : teams.docs.first.id;
    String selectedCategory = 'Boys';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final venueController = TextEditingController();
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
                    items: sports.docs.map((doc) {
                      final sport = SportModel.fromSnapshot(doc);
                      return DropdownMenuItem(
                        value: sport.id,
                        child: Text(sport.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedSportId = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Team 1 Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedTeam1Id,
                    decoration: const InputDecoration(
                      labelText: 'Team 1',
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: teams.docs.map((doc) {
                      final team = TeamModel.fromSnapshot(doc);
                      return DropdownMenuItem(
                        value: team.id,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedTeam1Id = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Team 2 Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedTeam2Id,
                    decoration: const InputDecoration(
                      labelText: 'Team 2',
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: teams.docs.map((doc) {
                      final team = TeamModel.fromSnapshot(doc);
                      return DropdownMenuItem(
                        value: team.id,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedTeam2Id = value);
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
}
