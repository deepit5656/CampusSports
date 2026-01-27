import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/cricket/cricket_match_config.dart';
import '../../../../core/models/cricket/cricket_inning.dart';
import '../../../../core/models/cricket/cricket_player.dart';
import '../../../../core/services/cricket_scoring_service.dart';

import 'cricket_live_scoring_screen.dart';

class CricketMatchSetupScreen extends StatefulWidget {
  final String matchId;
  final String team1Id;
  final String team1Name;
  final String team2Id;
  final String team2Name;

  const CricketMatchSetupScreen({
    Key? key,
    required this.matchId,
    required this.team1Id,
    required this.team1Name,
    required this.team2Id,
    required this.team2Name,
  }) : super(key: key);

  @override
  State<CricketMatchSetupScreen> createState() =>
      _CricketMatchSetupScreenState();
}

class _CricketMatchSetupScreenState extends State<CricketMatchSetupScreen> {
  final _cricketService = CricketScoringService();
  final _uuid = const Uuid();
  
  // Basic Settings
  final _oversController = TextEditingController(text: '20');
  String? _tossWonBy;
  TossDecision _tossDecision = TossDecision.bat;
  
  // Advanced Settings
  bool _showAdvancedSettings = false;
  final _playersPerTeamController = TextEditingController(text: '11');
  bool _noBallReball = true;
  final _noBallRunsController = TextEditingController(text: '1');
  bool _wideBallReball = true;
  final _wideBallRunsController = TextEditingController(text: '1');
  
  // Opening players
  List<CricketPlayer> _team1Players = [];
  List<CricketPlayer> _team2Players = [];
  CricketPlayer? _striker;
  CricketPlayer? _nonStriker;
  CricketPlayer? _openingBowler;
  
  bool _isLoading = false;
  bool _showOpeningPlayers = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final team1Players = await _cricketService.getTeamPlayers(widget.team1Id);
      final team2Players = await _cricketService.getTeamPlayers(widget.team2Id);
      
      setState(() {
        _team1Players = team1Players;
        _team2Players = team2Players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load players: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Future<void> _startMatch() async {
    // Validation
    if (_tossWonBy == null) {
      _showError('Please select who won the toss');
      return;
    }

    final overs = int.tryParse(_oversController.text);
    if (overs == null || overs <= 0) {
      _showError('Please enter valid number of overs');
      return;
    }

    if (!_showOpeningPlayers) {
      setState(() => _showOpeningPlayers = true);
      return;
    }

    // Validate opening players
    if (_striker == null || _nonStriker == null || _openingBowler == null) {
      _showError('Please select opening batsmen and bowler');
      return;
    }

    if (_striker!.id == _nonStriker!.id) {
      _showError('Striker and Non-striker must be different');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create match config
      final config = CricketMatchConfig(
        matchId: widget.matchId,
        team1Id: widget.team1Id,
        team2Id: widget.team2Id,
        totalOvers: overs,
        tossWonBy: _tossWonBy!,
        tossDecision: _tossDecision,
        playersPerTeam: int.tryParse(_playersPerTeamController.text) ?? 11,
        noBallReball: _noBallReball,
        noBallRuns: int.tryParse(_noBallRunsController.text) ?? 1,
        wideBallReball: _wideBallReball,
        wideBallRuns: int.tryParse(_wideBallRunsController.text) ?? 1,
        createdAt: DateTime.now(),
      );

      await _cricketService.saveMatchConfig(config);

      // Determine batting and bowling teams
      final battingTeamId = _tossDecision == TossDecision.bat
          ? _tossWonBy!
          : (_tossWonBy == widget.team1Id ? widget.team2Id : widget.team1Id);
      final bowlingTeamId = battingTeamId == widget.team1Id
          ? widget.team2Id
          : widget.team1Id;

      // Create first inning
      final inning = CricketInning(
        id: _uuid.v4(),
        matchId: widget.matchId,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        inningNumber: 1,
        currentStrikerId: _striker!.id,
        currentNonStrikerId: _nonStriker!.id,
        currentBowlerId: _openingBowler!.id,
        createdAt: DateTime.now(),
      );

      final inningId = await _cricketService.startInning(inning);

      setState(() => _isLoading = false);

      // Navigate to live scoring
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CricketLiveScoringScreen(
            matchId: widget.matchId,
            inningId: inningId,
            config: config,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to start match: $e');
    }
  }

  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teams',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildTeamCard(widget.team1Name, widget.team1Id),
        const SizedBox(height: 8),
        _buildTeamCard(widget.team2Name, widget.team2Id),
        const SizedBox(height: 24),

        // Toss
        const Text(
          'Toss won by?',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTossOption(widget.team1Id, widget.team1Name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTossOption(widget.team2Id, widget.team2Name),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Opted to
        const Text(
          'Opted to?',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTossDecisionOption(TossDecision.bat, 'Bat'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTossDecisionOption(TossDecision.bowl, 'Bowl'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Overs
        const Text(
          'Overs?',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _oversController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Enter number of overs',
            hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(String teamName, String teamId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGradientStart.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_cricket,
              color: AppTheme.primaryGradientStart,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              teamName,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTossOption(String teamId, String teamName) {
    final isSelected = _tossWonBy == teamId;
    return GestureDetector(
      onTap: () => setState(() => _tossWonBy = teamId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGradientStart : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGradientStart
                : AppTheme.textSecondary.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.textColor,
                size: 20,
              ),
            if (isSelected) const SizedBox(width: 8),
            Flexible(
              child: Text(
                teamName,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.textColor
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTossDecisionOption(TossDecision decision, String label) {
    final isSelected = _tossDecision == decision;
    return GestureDetector(
      onTap: () => setState(() => _tossDecision = decision),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGradientStart : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGradientStart
                : AppTheme.textSecondary.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.textColor,
                size: 20,
              ),
            if (isSelected) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textColor
                    : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _showAdvancedSettings = !_showAdvancedSettings);
          },
          icon: Icon(
            _showAdvancedSettings
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
          ),
          label: const Text('Advanced settings'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textColor,
            side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
          ),
        ),
        if (_showAdvancedSettings) ...[
          const SizedBox(height: 16),
          
          // Players per team
          const Text(
            'Players per team?',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _playersPerTeamController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // No Ball settings
          const Text(
            'No Ball',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Re-ball',
                      style: TextStyle(color: AppTheme.textColor),
                    ),
                    Switch(
                      value: _noBallReball,
                      onChanged: (value) {
                        setState(() => _noBallReball = value);
                      },
                      activeColor: AppTheme.primaryGradientStart,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noBallRunsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'No ball run',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Wide Ball settings
          const Text(
            'Wide Ball',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Re-ball',
                      style: TextStyle(color: AppTheme.textColor),
                    ),
                    Switch(
                      value: _wideBallReball,
                      onChanged: (value) {
                        setState(() => _wideBallReball = value);
                      },
                      activeColor: AppTheme.primaryGradientStart,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _wideBallRunsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Wide ball run',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpeningPlayersSelection() {
    // Determine which team is batting
    final battingTeamId = _tossDecision == TossDecision.bat
        ? _tossWonBy!
        : (_tossWonBy == widget.team1Id ? widget.team2Id : widget.team1Id);
    final bowlingTeamId = battingTeamId == widget.team1Id
        ? widget.team2Id
        : widget.team1Id;

    final battingPlayers = battingTeamId == widget.team1Id
        ? _team1Players
        : _team2Players;
    final bowlingPlayers = bowlingTeamId == widget.team1Id
        ? _team1Players
        : _team2Players;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Striker
        const Text(
          'Striker',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildPlayerDropdown(
          value: _striker,
          players: battingPlayers,
          hint: 'Select striker',
          onChanged: (player) => setState(() => _striker = player),
        ),
        const SizedBox(height: 16),

        // Non-striker
        const Text(
          'Non-striker',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildPlayerDropdown(
          value: _nonStriker,
          players: battingPlayers,
          hint: 'Select non-striker',
          onChanged: (player) => setState(() => _nonStriker = player),
        ),
        const SizedBox(height: 16),

        // Opening bowler
        const Text(
          'Opening bowler',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildPlayerDropdown(
          value: _openingBowler,
          players: bowlingPlayers,
          hint: 'Select opening bowler',
          onChanged: (player) => setState(() => _openingBowler = player),
        ),
      ],
    );
  }

  Widget _buildPlayerDropdown({
    required CricketPlayer? value,
    required List<CricketPlayer> players,
    required String hint,
    required void Function(CricketPlayer?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<CricketPlayer>(
        value: value,
        isExpanded: true,
        hint: Text(
          hint,
          style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
        ),
        dropdownColor: AppTheme.cardDark,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.textColor),
        items: players.map((player) {
          return DropdownMenuItem(
            value: player,
            child: Text(player.name),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Cricket Match Setup'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_showOpeningPlayers) ...[
                    _buildBasicSettings(),
                    _buildAdvancedSettings(),
                  ] else ...[
                    _buildOpeningPlayersSelection(),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _showOpeningPlayers ? 'Start match' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
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

