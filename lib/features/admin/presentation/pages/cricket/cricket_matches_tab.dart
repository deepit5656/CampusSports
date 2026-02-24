import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/team_model.dart';
import '../../../../../core/models/player_model.dart';

class CricketMatchesTab extends StatefulWidget {
  final String sportId;

  const CricketMatchesTab({Key? key, required this.sportId}) : super(key: key);

  @override
  State<CricketMatchesTab> createState() => _CricketMatchesTabState();
}

class _CricketMatchesTabState extends State<CricketMatchesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TeamModel? _hostTeam;
  TeamModel? _visitorTeam;
  String _tossWonBy = 'host';
  String _optedTo = 'bat';
  final _oversController = TextEditingController(text: '20');
  bool _showAdvancedSettings = false;

  // Advanced settings
  final _playersPerTeamController = TextEditingController(text: '11');
  bool _noBallEnabled = true;
  bool _noBallReball = true;
  final _noBallRunsController = TextEditingController(text: '1');
  bool _wideBallEnabled = true;
  bool _wideBallReball = true;
  final _wideBallRunsController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    if (_matchStarted) {
      return SingleChildScrollView(
        child: _buildMatchManagement(),
      ).animate().fadeIn();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildTeamSelection(),
          const SizedBox(height: 24),
          _buildTossSettings(),
          const SizedBox(height: 24),
          _buildOversSelection(),
          const SizedBox(height: 24),
          _buildAdvancedSettings(),
          const SizedBox(height: 32),
          _buildStartButton(),
          const SizedBox(height: 16),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_cricket, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'New Match Setup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure your cricket match',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelection() {
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
            'Teams',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTeamDropdown(
            label: 'Host Team',
            icon: Icons.home,
            value: _hostTeam,
            onChanged: (team) => setState(() => _hostTeam = team),
          ),
          const SizedBox(height: 16),
          _buildTeamDropdown(
            label: 'Visitor Team',
            icon: Icons.flight,
            value: _visitorTeam,
            onChanged: (team) => setState(() => _visitorTeam = team),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDropdown({
    required String label,
    required IconData icon,
    required TeamModel? value,
    required Function(TeamModel?) onChanged,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('teams').snapshots(),
      builder: (context, teamSnapshot) {
        if (!teamSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTeams = teamSnapshot.data!.docs
            .map((doc) => TeamModel.fromSnapshot(doc))
            .toList();

        // Filter to show only complete teams (with all players added)
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('players')
              .where('sportId', isEqualTo: widget.sportId)
              .snapshots(),
          builder: (context, playersSnapshot) {
            if (!playersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('sports')
                  .doc(widget.sportId)
                  .snapshots(),
              builder: (context, sportSnapshot) {
                final numberOfPlayers =
                    sportSnapshot.data?.get('numberOfPlayers') as int?;

                final teams = numberOfPlayers != null
                    ? allTeams.where((team) {
                        final playerCount = playersSnapshot.data!.docs
                            .where((doc) => doc.get('teamId') == team.id)
                            .length;
                        return playerCount == numberOfPlayers;
                      }).toList()
                    : [];

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFF10b981), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TeamModel>(
                            value: value,
                            hint: Text(
                              label,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            isExpanded: true,
                            dropdownColor: AppTheme.cardDark,
                            style: const TextStyle(color: Colors.white),
                            items: teams.map((team) {
                              return DropdownMenuItem<TeamModel>(
                                value: team,
                                child: Text(team.name),
                              );
                            }).toList(),
                            onChanged: onChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  label: _hostTeam?.name ?? 'Team 1',
                  value: 'host',
                  groupValue: _tossWonBy,
                  onChanged: (val) => setState(() => _tossWonBy = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  label: _visitorTeam?.name ?? 'Team 2',
                  value: 'visitor',
                  groupValue: _tossWonBy,
                  onChanged: (val) => setState(() => _tossWonBy = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Opted to',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  label: 'Bat',
                  value: 'bat',
                  groupValue: _optedTo,
                  onChanged: (val) => setState(() => _optedTo = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  label: 'Bowl',
                  value: 'bowl',
                  groupValue: _optedTo,
                  onChanged: (val) => setState(() => _optedTo = val!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected ? const Color(0xFF10b981) : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF10b981)
                    : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            'Overs',
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
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.av_timer, color: Color(0xFF10b981)),
              filled: true,
              fillColor: AppTheme.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
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
            onTap: () =>
                setState(() => _showAdvancedSettings = !_showAdvancedSettings),
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
                  color: const Color(0xFF10b981),
                ),
              ],
            ),
          ),
          if (_showAdvancedSettings) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            _buildPlayersPerTeam(),
            const SizedBox(height: 16),
            _buildNoBallSettings(),
            const SizedBox(height: 16),
            _buildWideBallSettings(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayersPerTeam() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Players per Team',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _playersPerTeamController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '11',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoBallSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'No Ball',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            Switch(
              value: _noBallEnabled,
              onChanged: (val) => setState(() => _noBallEnabled = val),
              activeColor: const Color(0xFF10b981),
            ),
          ],
        ),
        if (_noBallEnabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _noBallReball,
                      onChanged: (val) => setState(() => _noBallReball = val!),
                      activeColor: const Color(0xFF10b981),
                    ),
                    const Text(
                      'Re-ball',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _noBallRunsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Runs',
                    labelStyle:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWideBallSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Wide Ball',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            Switch(
              value: _wideBallEnabled,
              onChanged: (val) => setState(() => _wideBallEnabled = val),
              activeColor: const Color(0xFF10b981),
            ),
          ],
        ),
        if (_wideBallEnabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _wideBallReball,
                      onChanged: (val) =>
                          setState(() => _wideBallReball = val!),
                      activeColor: const Color(0xFF10b981),
                    ),
                    const Text(
                      'Re-ball',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _wideBallRunsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Runs',
                    labelStyle:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _startMatch,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10b981),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow, size: 28),
          SizedBox(width: 8),
          Text(
            'Start Match',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _startMatch() {
    if (_hostTeam == null || _visitorTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both teams'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_hostTeam!.id == _visitorTeam!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Host and Visitor teams must be different'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final overs = int.tryParse(_oversController.text);
    if (overs == null || overs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of overs'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Determine which team bats first
    final tossWinner = _tossWonBy == 'host' ? _hostTeam! : _visitorTeam!;
    final battingTeam = _optedTo == 'bat'
        ? tossWinner
        : (_tossWonBy == 'host' ? _visitorTeam! : _hostTeam!);
    final bowlingTeam =
        battingTeam.id == _hostTeam!.id ? _visitorTeam! : _hostTeam!;

    // Show inline match management
    setState(() {
      _matchStarted = true;
      _battingTeam = battingTeam;
      _bowlingTeam = bowlingTeam;
      _overs = overs;
    });
  }

  // Match state
  bool _matchStarted = false;
  TeamModel? _battingTeam;
  TeamModel? _bowlingTeam;
  int? _overs;
  int _runs = 0;
  int _wickets = 0;
  double _currentOver = 0.0;
  int _ballsInOver = 0;
  String? _striker;
  String? _nonStriker;
  String? _currentBowler;

  List<Map<String, dynamic>> _scoreHistory = [];

  void _recordBall(int runs,
      {bool isWide = false, bool isNoBall = false, bool isWicket = false}) {
    setState(() {
      if (isWide || isNoBall) {
        _runs += runs + 1; // Extra run for wide/no-ball
        // Don't increment ball count for wide/no-ball
      } else {
        _runs += runs;
        _ballsInOver++;

        if (_ballsInOver == 6) {
          _currentOver++;
          _ballsInOver = 0;
        } else {
          _currentOver = _currentOver.floor() + (_ballsInOver / 10.0);
        }
      }

      if (isWicket) {
        _wickets++;
      }

      if (runs % 2 == 1) {
        // Swap striker and non-striker on odd runs
        final temp = _striker;
        _striker = _nonStriker;
        _nonStriker = temp;
      }

      _scoreHistory.add({
        'ball': _currentOver.toStringAsFixed(1),
        'runs': runs,
        'isWide': isWide,
        'isNoBall': isNoBall,
        'isWicket': isWicket,
        'totalRuns': _runs,
        'totalWickets': _wickets,
      });
    });
  }

  Widget _buildMatchManagement() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scoreboard
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  _battingTeam!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_runs / $_wickets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Overs: ${_currentOver.toStringAsFixed(1)} / $_overs',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Players
          Row(
            children: [
              Expanded(
                child: _buildPlayerCard('Striker', _striker, true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerCard('Non-Striker', _nonStriker, false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPlayerCard('Bowler', _currentBowler, false, isBowler: true),
          const SizedBox(height: 24),

          // Scoring buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildScoreButton('0', 0),
              _buildScoreButton('1', 1),
              _buildScoreButton('2', 2),
              _buildScoreButton('3', 3),
              _buildScoreButton('4', 4),
              _buildScoreButton('6', 6),
              _buildScoreButton('Wide', 0, isWide: true),
              _buildScoreButton('No Ball', 0, isNoBall: true),
              _buildScoreButton('Wicket', 0, isWicket: true),
            ],
          ),
          const SizedBox(height: 24),

          // Current over
          if (_scoreHistory.isNotEmpty) ...[
            const Text(
              'Current Over',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: (_scoreHistory.length <= 6
                      ? _scoreHistory
                      : _scoreHistory.sublist(_scoreHistory.length - 6))
                  .map((ball) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ball['isWicket']
                        ? AppTheme.errorColor
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ball['isWide'] || ball['isNoBall']
                          ? AppTheme.accentGradientStart
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      ball['isWicket'] ? 'W' : ball['runs'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),

          // End match button
          ElevatedButton(
            onPressed: () {
              setState(() {
                _matchStarted = false;
                _runs = 0;
                _wickets = 0;
                _currentOver = 0.0;
                _ballsInOver = 0;
                _scoreHistory.clear();
                _striker = null;
                _nonStriker = null;
                _currentBowler = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('End Match'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String role, String? playerName, bool isStriker,
      {bool isBowler = false}) {
    return GestureDetector(
      onTap: () => _selectPlayer(role, isBowler),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isStriker
                ? AppTheme.accentGradientStart
                : AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              playerName ?? 'Select Player',
              style: TextStyle(
                color:
                    playerName != null ? Colors.white : AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPlayer(String role, bool isBowler) async {
    final team = isBowler ? _bowlingTeam! : _battingTeam!;
    final playersSnapshot = await _firestore
        .collection('players')
        .where('teamId', isEqualTo: team.id)
        .where('sportId', isEqualTo: widget.sportId)
        .get();

    final players =
        playersSnapshot.docs.map((doc) => doc.get('name') as String).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Select $role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: players.map((player) {
            return ListTile(
              title: Text(player),
              onTap: () {
                setState(() {
                  if (role == 'Striker')
                    _striker = player;
                  else if (role == 'Non-Striker')
                    _nonStriker = player;
                  else if (role == 'Bowler') _currentBowler = player;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScoreButton(String label, int runs,
      {bool isWide = false, bool isNoBall = false, bool isWicket = false}) {
    return ElevatedButton(
      onPressed: () => _recordBall(runs,
          isWide: isWide, isNoBall: isNoBall, isWicket: isWicket),
      style: ElevatedButton.styleFrom(
        backgroundColor: isWicket ? AppTheme.errorColor : AppTheme.cardDark,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
