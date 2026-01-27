import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/cricket/cricket_player.dart';
import '../../../../core/services/cricket_scoring_service.dart';
import '../../../../core/theme/app_theme.dart';


class CricketPlayerManagementScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const CricketPlayerManagementScreen({
    Key? key,
    required this.teamId,
    required this.teamName,
  }) : super(key: key);

  @override
  State<CricketPlayerManagementScreen> createState() =>
      _CricketPlayerManagementScreenState();
}

class _CricketPlayerManagementScreenState
    extends State<CricketPlayerManagementScreen> {
  final _cricketService = CricketScoringService();
  final _uuid = const Uuid();
  List<CricketPlayer> _players = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final players = await _cricketService.getTeamPlayers(widget.teamId);
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load players: $e');
    }
  }

  void _showAddPlayerDialog([CricketPlayer? player]) {
    final isEdit = player != null;
    final nameController = TextEditingController(text: player?.name ?? '');
    final jerseyController = TextEditingController(
        text: player?.jerseyNumber.toString() ?? '');
    PlayerRole selectedRole = player?.role ?? PlayerRole.batsman;
    bool isCaptain = player?.isCaptain ?? false;
    bool isWicketKeeper = player?.isWicketKeeper ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: Text(
            isEdit ? 'Edit Player' : 'Add Player',
            style: const TextStyle(color: AppTheme.textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player Name
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Player Name *',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGradientStart),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Jersey Number
                TextField(
                  controller: jerseyController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Jersey Number',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGradientStart),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Role Selection
                const Text(
                  'Role *',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PlayerRole.values.map((role) {
                    final isSelected = selectedRole == role;
                    return ChoiceChip(
                      label: Text(_getRoleDisplayName(role)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() => selectedRole = role);
                      },
                      backgroundColor: AppTheme.surfaceDark,
                      selectedColor: AppTheme.primaryGradientStart,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.textColor
                            : AppTheme.textSecondary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Captain Checkbox
                CheckboxListTile(
                  title: const Text(
                    'Captain',
                    style: TextStyle(color: AppTheme.textColor),
                  ),
                  value: isCaptain,
                  onChanged: (value) {
                    setDialogState(() => isCaptain = value ?? false);
                  },
                  activeColor: AppTheme.primaryGradientStart,
                  contentPadding: EdgeInsets.zero,
                ),

                // Wicket Keeper Checkbox
                CheckboxListTile(
                  title: const Text(
                    'Wicket Keeper',
                    style: TextStyle(color: AppTheme.textColor),
                  ),
                  value: isWicketKeeper,
                  onChanged: (value) {
                    setDialogState(() => isWicketKeeper = value ?? false);
                  },
                  activeColor: AppTheme.primaryGradientStart,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showError('Please enter player name');
                  return;
                }

                final newPlayer = CricketPlayer(
                  id: player?.id ?? _uuid.v4(),
                  name: nameController.text.trim(),
                  teamId: widget.teamId,
                  role: selectedRole,
                  jerseyNumber: int.tryParse(jerseyController.text) ?? 0,
                  isCaptain: isCaptain,
                  isWicketKeeper: isWicketKeeper,
                  createdAt: player?.createdAt ?? DateTime.now(),
                );

                try {
                  if (isEdit) {
                    await _cricketService.updatePlayer(newPlayer);
                  } else {
                    await _cricketService.addPlayer(newPlayer);
                  }
                  Navigator.pop(context);
                  _loadPlayers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit
                          ? 'Player updated successfully'
                          : 'Player added successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } catch (e) {
                  _showError('Failed to save player: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGradientStart,
              ),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(PlayerRole role) {
    switch (role) {
      case PlayerRole.batsman:
        return 'Batsman';
      case PlayerRole.bowler:
        return 'Bowler';
      case PlayerRole.allRounder:
        return 'All-Rounder';
      case PlayerRole.wicketKeeper:
        return 'Wicket Keeper';
    }
  }

  IconData _getRoleIcon(PlayerRole role) {
    switch (role) {
      case PlayerRole.batsman:
        return Icons.sports_cricket;
      case PlayerRole.bowler:
        return Icons.sports_baseball;
      case PlayerRole.allRounder:
        return Icons.star;
      case PlayerRole.wicketKeeper:
        return Icons.sports_handball;
    }
  }

  void _deletePlayer(CricketPlayer player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Delete Player',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete ${player.name}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _cricketService.deletePlayer(player.id);
                Navigator.pop(context);
                _loadPlayers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Player deleted successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                _showError('Failed to delete player: $e');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('${widget.teamName} - Players'),
        backgroundColor: AppTheme.primaryGradientStart,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 64,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No players added yet',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add players',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return Card(
                      color: AppTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGradientStart.withOpacity(0.2),
                          child: player.jerseyNumber > 0
                              ? Text(
                                  player.jerseyNumber.toString(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryGradientStart,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Icon(
                                  _getRoleIcon(player.role),
                                  color: AppTheme.primaryGradientStart,
                                ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                player.name,
                                style: const TextStyle(
                                  color: AppTheme.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (player.isCaptain)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'C',
                                  style: TextStyle(
                                    color: AppTheme.warningColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (player.isWicketKeeper)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'WK',
                                  style: TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _getRoleDisplayName(player.role),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.primaryGradientStart),
                              onPressed: () => _showAddPlayerDialog(player),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                              onPressed: () => _deletePlayer(player),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlayerDialog(),
        backgroundColor: AppTheme.primaryGradientStart,
        icon: const Icon(Icons.add),
        label: const Text('Add Player'),
      ),
    );
  }
}

