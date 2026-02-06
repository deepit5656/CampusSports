import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/team_model.dart';
import '../../../../../core/models/player_model.dart';
import '../../../../../core/utils/validators.dart';

class CricketTeamsTab extends StatefulWidget {
  final String sportId;

  const CricketTeamsTab({Key? key, required this.sportId}) : super(key: key);

  @override
  State<CricketTeamsTab> createState() => _CricketTeamsTabState();
}

class _CricketTeamsTabState extends State<CricketTeamsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? _numberOfPlayers;

  @override
  void initState() {
    super.initState();
    _loadNumberOfPlayers();
  }

  Future<void> _loadNumberOfPlayers() async {
    final sportDoc = await _firestore.collection('sports').doc(widget.sportId).get();
    if (sportDoc.exists) {
      setState(() {
        _numberOfPlayers = sportDoc.data()?['numberOfPlayers'] as int?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Number of players setting at top
        if (_numberOfPlayers == null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentGradientStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentGradientStart),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.accentGradientStart),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Set number of players for Cricket teams',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _showSetNumberOfPlayersDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGradientStart,
                  ),
                  child: const Text('Set Now'),
                ),
              ],
            ),
          ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('teams')
                .snapshots(),
            builder: (context, teamSnapshot) {
              if (!teamSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allTeams = teamSnapshot.data!.docs
                  .map((doc) => TeamModel.fromSnapshot(doc))
                  .toList();

              // Only show teams that have added all required players for cricket
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('players').where('sportId', isEqualTo: widget.sportId).snapshots(),
                builder: (context, playersSnapshot) {
                  if (!playersSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final teams = allTeams.where((team) {
                    final playerCount = playersSnapshot.data!.docs
                        .where((doc) => doc.get('teamId') == team.id)
                        .length;
                    return _numberOfPlayers != null && playerCount == _numberOfPlayers;
                  }).toList();

                  if (teams.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      return _buildTeamCard(teams[index], index);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.groups_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Complete Teams Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _numberOfPlayers == null 
                ? 'Set number of players first'
                : 'Teams will appear here once all $_numberOfPlayers players are added',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team, int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('players')
          .where('teamId', isEqualTo: team.id)
          .where('sportId', isEqualTo: widget.sportId)
          .snapshots(),
      builder: (context, playersSnapshot) {
        final playerCount = playersSnapshot.hasData ? playersSnapshot.data!.docs.length : 0;
        final numberOfPlayers = _numberOfPlayers ?? 0;

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
                    team.name.substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.department,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (numberOfPlayers > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Players: $playerCount / $numberOfPlayers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: playerCount == numberOfPlayers
                                  ? AppTheme.successColor
                                  : AppTheme.accentGradientStart,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.people, color: numberOfPlayers > 0 ? AppTheme.primaryGradientStart : AppTheme.textSecondary),
                onPressed: numberOfPlayers > 0
                    ? () => _showPlayersDialog(team)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetNumberOfPlayersDialog() {
    final numberOfPlayersController = TextEditingController(
      text: _numberOfPlayers?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Set Number of Players for Cricket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: numberOfPlayersController,
              decoration: const InputDecoration(
                labelText: 'Number of Players per Team',
                prefixIcon: Icon(Icons.people),
                hintText: 'e.g., 11 for standard cricket',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'This will apply to all cricket teams',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(numberOfPlayersController.text.trim());
              if (count != null && count > 0) {
                try {
                  await _firestore.collection('sports').doc(widget.sportId).set({
                    'numberOfPlayers': count,
                  }, SetOptions(merge: true));
                  setState(() {
                    _numberOfPlayers = count;
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Number of players set successfully!'),
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
                }
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPlayersDialog(TeamModel team) {
    showDialog(
      context: context,
      builder: (dialogContext) => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('players')
            .where('teamId', isEqualTo: team.id)
            .where('sportId', isEqualTo: widget.sportId)
            .snapshots(),
        builder: (context, playersSnapshot) {
          final players = playersSnapshot.hasData
              ? playersSnapshot.data!.docs.map((doc) => PlayerModel.fromSnapshot(doc)).toList()
              : <PlayerModel>[];

          return Dialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${team.name} Players',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _numberOfPlayers ?? 0,
                      itemBuilder: (context, index) {
                        final player = index < players.length ? players[index] : null;
                        return _buildPlayerField(team, index + 1, player);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerField(TeamModel team, int position, PlayerModel? player) {
    final role = player?.additionalInfo?['role'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player != null ? AppTheme.successColor : AppTheme.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: player != null ? AppTheme.successColor : AppTheme.textSecondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: const TextStyle(
                  color: Colors.white,
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
                  player?.name ?? 'Empty Slot',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: player != null ? null : AppTheme.textSecondary,
                      ),
                ),
                if (player != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${player.idNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  if (role.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Role: $role',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentGradientStart,
                          ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (player != null)
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => _deletePlayer(player),
            )
          else
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.accentGradientStart),
              onPressed: () => _showAddPlayerDialog(team, position),
            ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(TeamModel team, int position) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    String selectedRole = 'Batsman';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Add Player #$position'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Player Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Player name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'ID Number',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'ID number'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.sports_cricket),
                  ),
                  items: ['Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final docRef = _firestore.collection('players').doc();
                  final newPlayer = PlayerModel(
                    id: docRef.id,
                    name: nameController.text.trim(),
                    idNumber: idController.text.trim(),
                    teamId: team.id,
                    sportId: widget.sportId,
                    createdAt: DateTime.now(),
                    additionalInfo: {'role': selectedRole},
                  );

                  await docRef.set(newPlayer.toMap());
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Player added successfully!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePlayer(PlayerModel player) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Player'),
        content: Text('Remove ${player.name} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('players').doc(player.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player removed successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
