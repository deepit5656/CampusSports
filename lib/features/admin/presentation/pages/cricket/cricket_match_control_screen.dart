import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/models/team_model.dart';
import '../../../../../core/services/cricket_scoring_service.dart';
import '../cricket_match_setup_screen.dart';
import '../cricket_player_management_screen.dart';

class CricketMatchControlScreen extends StatefulWidget {
  final String matchId;

  const CricketMatchControlScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<CricketMatchControlScreen> createState() => _CricketMatchControlScreenState();
}

class _CricketMatchControlScreenState extends State<CricketMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MatchModel? _match;
  TeamModel? _hostTeam;
  TeamModel? _visitorTeam;
  String _tossWonBy = 'host';
  String _optedTo = 'bat';
  final _oversController = TextEditingController(text: '20');
  bool _showAdvancedSettings = false;
  bool _isLoading = true;
  bool _tossCompleted = false;
  String _selectedStatus = 'upcoming';

  // Advanced settings
  final _playersPerTeamController = TextEditingController(text: '11');
  bool _noBallEnabled = true;
  final _noBallRunsController = TextEditingController(text: '1');
  bool _wideBallEnabled = true;
  final _wideBallRunsController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      final matchDoc = await _firestore.collection('matches').doc(widget.matchId).get();
      if (!matchDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      _match = MatchModel.fromSnapshot(matchDoc);
      _selectedStatus = _match!.status;

      // Load teams
      final team1Doc = await _firestore.collection('teams').doc(_match!.team1Id).get();
      final team2Doc = await _firestore.collection('teams').doc(_match!.team2Id).get();
      
      if (!team1Doc.exists || !team2Doc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      _hostTeam = TeamModel.fromSnapshot(team1Doc);
      _visitorTeam = TeamModel.fromSnapshot(team2Doc);

      // Check if toss is already completed
      final cricketMatchData = matchDoc.data()?['cricketMatchData'] as Map<String, dynamic>?;
      if (cricketMatchData != null) {
        _tossCompleted = cricketMatchData['tossWonBy'] != null;
        if (_tossCompleted) {
          _tossWonBy = cricketMatchData['tossWonBy'] ?? 'host';
          _optedTo = cricketMatchData['optedTo'] ?? 'bat';
          _oversController.text = cricketMatchData['overs']?.toString() ?? '20';
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading match: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Match Control'),
          backgroundColor: AppTheme.primaryGradientStart,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_match == null || _hostTeam == null || _visitorTeam == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Match Control'),
          backgroundColor: AppTheme.primaryGradientStart,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Unable to Load Match Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please ensure teams have complete player rosters before managing this match.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_cricket, color: Color(0xFF10b981)),
            const SizedBox(width: 8),
            const Text('Cricket Match Control'),
          ],
        ),
        backgroundColor: AppTheme.primaryGradientStart,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMatchInfo(),
            const SizedBox(height: 24),
            _buildStatusControl(),
            const SizedBox(height: 24),
            if (!_tossCompleted) ...[
              _buildTossSettings(),
              const SizedBox(height: 24),
              _buildOversSelection(),
              const SizedBox(height: 24),
              _buildAdvancedSettings(),
              const SizedBox(height: 24),
              _buildSaveTossButton(),
            ] else ...[
              _buildTossInfo(),
              const SizedBox(height: 24),
              _buildPlayerManagement(),
            const SizedBox(height: 24),
            if (_selectedStatus == 'live') _buildStartMatchButton(),
            ],
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildMatchInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _hostTeam!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _visitorTeam!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(
                _match!.venue,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusControl() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Match Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('Upcoming', 'upcoming'),
              _buildStatusChip('Live', 'live'),
              _buildStatusChip('Completed', 'completed'),
              _buildStatusChip('Cancelled', 'cancelled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
          
          // Update status in Firestore
          try {
            await _firestore.collection('matches').doc(widget.matchId).update({
              'status': value,
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status updated to $label'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating status: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      },
      selectedColor: AppTheme.successColor,
      backgroundColor: AppTheme.backgroundDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTossInfo() {
    final tossWinner = _tossWonBy == 'host' ? _hostTeam!.name : _visitorTeam!.name;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Toss Completed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Won by:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      tossWinner,
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Opted to:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      _optedTo.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overs:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      _oversController.text,
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _tossCompleted = false;
              });
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Toss'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentGradientStart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTossSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Toss',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Toss won by',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTossOption(
                  label: 'Host',
                  value: 'host',
                  isSelected: _tossWonBy == 'host',
                  onTap: () => setState(() => _tossWonBy = 'host'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTossOption(
                  label: 'Visitor',
                  value: 'visitor',
                  isSelected: _tossWonBy == 'visitor',
                  onTap: () => setState(() => _tossWonBy = 'visitor'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Opted to',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTossOption(
                  label: 'Bat',
                  value: 'bat',
                  isSelected: _optedTo == 'bat',
                  onTap: () => setState(() => _optedTo = 'bat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTossOption(
                  label: 'Bowl',
                  value: 'bowl',
                  isSelected: _optedTo == 'bowl',
                  onTap: () => setState(() => _optedTo = 'bowl'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTossOption({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10b981).withOpacity(0.2)
              : AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10b981)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(
                Icons.radio_button_checked,
                color: Color(0xFF10b981),
                size: 20,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF10b981) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOversSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Match Overs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _oversController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter number of overs',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: const Icon(Icons.timelapse, color: Color(0xFF10b981)),
              filled: true,
              fillColor: AppTheme.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['5', '10', '20', '50'].map((overs) {
              return ActionChip(
                label: Text('$overs Overs'),
                onPressed: () => setState(() => _oversController.text = overs),
                backgroundColor: AppTheme.backgroundDark,
                labelStyle: const TextStyle(color: Color(0xFF10b981)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          InkWell(
            onTap: () => setState(() => _showAdvancedSettings = !_showAdvancedSettings),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          if (_showAdvancedSettings) ...[
            const SizedBox(height: 20),
            // No Ball Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('No Ball', style: TextStyle(color: Colors.white)),
                Switch(
                  value: _noBallEnabled,
                  onChanged: (value) => setState(() => _noBallEnabled = value),
                  activeColor: const Color(0xFF10b981),
                ),
              ],
            ),
            // Wide Ball Settings
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Wide Ball', style: TextStyle(color: Colors.white)),
                Switch(
                  value: _wideBallEnabled,
                  onChanged: (value) => setState(() => _wideBallEnabled = value),
                  activeColor: const Color(0xFF10b981),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveTossButton() {
    return ElevatedButton(
      onPressed: _saveTossSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10b981),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Save Toss Settings',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStartMatchButton() {
    return ElevatedButton.icon(
      onPressed: _startMatch,
      icon: const Icon(Icons.play_arrow, size: 24),
      label: const Text(
        'Start Match',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Future<void> _saveTossSettings() async {
    if (_oversController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter number of overs'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('matches').doc(widget.matchId).update({
        'cricketMatchData': {
          'tossWonBy': _tossWonBy,
          'optedTo': _optedTo,
          'overs': int.parse(_oversController.text),
          'playersPerTeam': int.parse(_playersPerTeamController.text),
          'noBallEnabled': _noBallEnabled,
          'noBallRuns': int.parse(_noBallRunsController.text),
          'wideBallEnabled': _wideBallEnabled,
          'wideBallRuns': int.parse(_wideBallRunsController.text),
        },
      });

      setState(() {
        _tossCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toss settings saved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving toss: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildPlayerManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.people, color: Color(0xFF10b981), size: 22),
              SizedBox(width: 8),
              Text(
                'Player Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Add players for both teams before starting the match',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPlayerMgmtButton(
                  _hostTeam!.name,
                  _match!.team1Id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerMgmtButton(
                  _visitorTeam!.name,
                  _match!.team2Id,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerMgmtButton(String teamName, String teamId) {
    return FutureBuilder<List>(
      future: CricketScoringService().getTeamPlayers(teamId),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CricketPlayerManagementScreen(
                  teamId: teamId,
                  teamName: teamName,
                ),
              ),
            );
            setState(() {}); // Refresh player counts
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            children: [
              Text(
                teamName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$count players',
                style: TextStyle(
                  fontSize: 11,
                  color: count > 0 ? const Color(0xFF10b981) : AppTheme.warningColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startMatch() async {
    if (!_tossCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete toss settings first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Navigate to cricket match setup for player selection & live scoring
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CricketMatchSetupScreen(
            matchId: widget.matchId,
            team1Id: _match!.team1Id,
            team1Name: _hostTeam!.name,
            team2Id: _match!.team2Id,
            team2Name: _visitorTeam!.name,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _oversController.dispose();
    _playersPerTeamController.dispose();
    _noBallRunsController.dispose();
    _wideBallRunsController.dispose();
    super.dispose();
  }
}
