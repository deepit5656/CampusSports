import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/cricket/cricket_ball.dart';
import '../../../../core/models/cricket/cricket_batting_stats.dart';
import '../../../../core/models/cricket/cricket_bowling_stats.dart';
import '../../../../core/models/cricket/cricket_inning.dart';
import '../../../../core/models/cricket/cricket_match_config.dart';
import '../../../../core/models/cricket/cricket_player.dart';
import '../../../../core/services/cricket_scoring_service.dart';

class CricketLiveScoringScreen extends StatefulWidget {
  final String matchId;
  final String inningId;
  final CricketMatchConfig config;

  const CricketLiveScoringScreen({
    Key? key,
    required this.matchId,
    required this.inningId,
    required this.config,
  }) : super(key: key);

  @override
  State<CricketLiveScoringScreen> createState() =>
      _CricketLiveScoringScreenState();
}

class _CricketLiveScoringScreenState extends State<CricketLiveScoringScreen> {
  final _cricketService = CricketScoringService();
  final _uuid = const Uuid();

  CricketInning? _inning;
  List<CricketBattingStats> _battingStats = [];
  List<CricketBowlingStats> _bowlingStats = [];
  List<CricketBall> _currentOverBalls = [];

  CricketPlayer? _striker;
  CricketPlayer? _nonStriker;
  CricketPlayer? _currentBowler;

  // Scoring options
  bool _isWide = false;
  bool _isNoBall = false;
  bool _isBye = false;
  bool _isLegBye = false;
  bool _isWicket = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    setState(() => _isLoading = true);
    try {
      final inning = await _cricketService.getInning(widget.inningId);
      final battingStats =
          await _cricketService.getInningBattingStats(widget.inningId);
      final bowlingStats =
          await _cricketService.getInningBowlingStats(widget.inningId);
      final allBalls = await _cricketService.getInningBalls(widget.inningId);

      final currentOver = inning?.overs.floor() ?? 0;
      final overBalls =
          allBalls.where((b) => b.overNumber == currentOver).toList();

      // Load current players
      CricketPlayer? striker;
      CricketPlayer? nonStriker;
      CricketPlayer? bowler;

      if (inning?.currentStrikerId != null) {
        striker = await _getPlayer(inning!.currentStrikerId!);
      }
      if (inning?.currentNonStrikerId != null) {
        nonStriker = await _getPlayer(inning!.currentNonStrikerId!);
      }
      if (inning?.currentBowlerId != null) {
        bowler = await _getPlayer(inning!.currentBowlerId!);
      }

      setState(() {
        _inning = inning;
        _battingStats = battingStats;
        _bowlingStats = bowlingStats;
        _currentOverBalls = overBalls;
        _striker = striker;
        _nonStriker = nonStriker;
        _currentBowler = bowler;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load match data: $e');
    }
  }

  Future<CricketPlayer?> _getPlayer(String playerId) async {
    // You would implement this to fetch from your player cache or service
    // For now, returning null
    return null;
  }

  void _resetScoringOptions() {
    setState(() {
      _isWide = false;
      _isNoBall = false;
      _isBye = false;
      _isLegBye = false;
      _isWicket = false;
    });
  }

  Future<void> _recordRuns(int runs) async {
    if (_striker == null || _nonStriker == null || _currentBowler == null) {
      _showError('Players not selected');
      return;
    }

    if (_inning == null) return;

    // Determine ball type
    BallType ballType = BallType.normal;
    int extras = 0;
    int actualRuns = runs;

    if (_isWide) {
      ballType = runs > 0 ? BallType.widePlusRuns : BallType.wide;
      extras = widget.config.wideBallRuns + runs;
      actualRuns = 0; // Batsman doesn't get credit for wide runs
    } else if (_isNoBall) {
      ballType = runs > 0 ? BallType.noBallPlusRuns : BallType.noBall;
      extras = widget.config.noBallRuns;
      actualRuns = runs; // Batsman gets credit for runs off no-ball
    } else if (_isBye) {
      ballType = BallType.bye;
      extras = runs;
      actualRuns = 0; // Batsman doesn't get credit
    } else if (_isLegBye) {
      ballType = BallType.legBye;
      extras = runs;
      actualRuns = 0; // Batsman doesn't get credit
    }

    // Calculate ball number
    int ballNumber = _currentOverBalls.length + 1;
    int overNumber = _inning!.overs.floor();

    // Create ball record
    final ball = CricketBall(
      id: _uuid.v4(),
      matchId: widget.matchId,
      inningId: widget.inningId,
      overNumber: overNumber,
      ballNumber: ballNumber,
      batsmanId: _striker!.id,
      nonStrikerId: _nonStriker!.id,
      bowlerId: _currentBowler!.id,
      ballType: ballType,
      runs: actualRuns,
      extras: extras,
      isWicket: _isWicket,
      isFour: runs == 4 && !_isBye && !_isLegBye,
      isSix: runs == 6 && !_isBye && !_isLegBye,
      createdAt: DateTime.now(),
    );

    try {
      await _cricketService.recordBall(ball, widget.config);

      // Check if we need to swap batsmen
      final totalRuns = actualRuns + extras;
      final shouldSwap = (totalRuns % 2 == 1); // Odd runs, swap batsmen

      // Check if over is complete
      final newOvers = _inning!.overs + (ball.isValidBall ? 0.1 : 0.0);
      final isOverComplete = _cricketService.isOverComplete(newOvers);

      if (shouldSwap && !isOverComplete) {
        // Swap striker and non-striker
        final temp = _striker;
        setState(() {
          _striker = _nonStriker;
          _nonStriker = temp;
        });
      } else if (isOverComplete) {
        // Auto-swap at end of over
        final temp = _striker;
        setState(() {
          _striker = _nonStriker;
          _nonStriker = temp;
        });
      }

      _resetScoringOptions();
      await _loadMatchData();
    } catch (e) {
      _showError('Failed to record ball: $e');
    }
  }

  Future<void> _undoLastBall() async {
    try {
      await _cricketService.undoLastBall(widget.inningId);
      await _loadMatchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last ball undone'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      _showError('Failed to undo: $e');
    }
  }

  void _swapBatsmen() {
    final temp = _striker;
    setState(() {
      _striker = _nonStriker;
      _nonStriker = temp;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Widget _buildScoreHeader() {
    if (_inning == null) return const SizedBox();

    final crr = _cricketService.calculateRunRate(
      _inning!.totalRuns,
      _inning!.overs,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Batting, ${_inning!.inningNumber}${_inning!.inningNumber == 1 ? 'st' : 'nd'} inning',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_inning!.totalRuns} - ${_inning!.wickets}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '(${_inning!.overs.toStringAsFixed(1)})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CRR',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    crr.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattingScorecard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppTheme.surfaceDark.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Batsman',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatHeader('R'),
              _buildStatHeader('B'),
              _buildStatHeader('4s'),
              _buildStatHeader('6s'),
              _buildStatHeader('SR'),
            ],
          ),
        ),
        ..._battingStats.take(3).map((stat) {
          final isStriker = _striker?.id == stat.playerId;
          return Container(
            color: isStriker
                ? AppTheme.surfaceDark.withOpacity(0.5)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          stat.playerName,
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontWeight:
                                isStriker ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isStriker)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            '*',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatValue(stat.runs.toString()),
                _buildStatValue(stat.ballsFaced.toString()),
                _buildStatValue(stat.fours.toString()),
                _buildStatValue(stat.sixes.toString()),
                _buildStatValue(stat.displayStrikeRate),
              ],
            ),
          );
        }).toList(),
        if (_currentBowler != null) ...[
          const SizedBox(height: 8),
          Container(
            color: AppTheme.surfaceDark.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Bowler',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatHeader('O'),
                _buildStatHeader('M'),
                _buildStatHeader('R'),
                _buildStatHeader('W'),
                _buildStatHeader('ER'),
              ],
            ),
          ),
          ..._bowlingStats
              .where((s) => s.playerId == _currentBowler!.id)
              .map((stat) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      stat.playerName,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatValue(stat.displayOvers),
                  _buildStatValue(stat.maidens.toString()),
                  _buildStatValue(stat.runs.toString()),
                  _buildStatValue(stat.wickets.toString()),
                  _buildStatValue(stat.displayEconomyRate),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildStatHeader(String text) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatValue(String text) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCurrentOver() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This over:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentOverBalls.map((ball) {
              return _buildBallChip(ball);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBallChip(CricketBall ball) {
    Color bgColor = AppTheme.cardDark;
    Color textColor = AppTheme.textColor;
    String display = ball.runs.toString();

    if (ball.isWicket) {
      bgColor = AppTheme.errorColor;
      textColor = Colors.white;
      display = 'W';
    } else if (ball.isSix) {
      bgColor = Colors.purple;
      textColor = Colors.white;
      display = '6';
    } else if (ball.isFour) {
      bgColor = Colors.blue;
      textColor = Colors.white;
      display = '4';
    } else if (ball.ballType == BallType.wide) {
      bgColor = Colors.orange;
      textColor = Colors.white;
      display = 'WD';
    } else if (ball.ballType == BallType.noBall) {
      bgColor = Colors.red.shade300;
      textColor = Colors.white;
      display = 'NB';
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          display,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildScoringOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildOptionChip('Wide', _isWide, () {
                setState(() => _isWide = !_isWide);
              }),
              _buildOptionChip('No Ball', _isNoBall, () {
                setState(() => _isNoBall = !_isNoBall);
              }),
              _buildOptionChip('Byes', _isBye, () {
                setState(() => _isBye = !_isBye);
              }),
              _buildOptionChip('Leg Byes', _isLegBye, () {
                setState(() => _isLegBye = !_isLegBye);
              }),
              _buildOptionChip('Wicket', _isWicket, () {
                setState(() => _isWicket = !_isWicket);
              }),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _retireBatsman();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Retire'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _swapBatsmen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Swap Batsman'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _undoLastBall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor.withOpacity(0.2),
                    foregroundColor: AppTheme.warningColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Undo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _showPartnerships,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Partnerships'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _showExtrasBreakdown,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Extras'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade700 : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Colors.green.shade700
                : AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRunButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i <= 3; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildRunButton(i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 4; i <= 6; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildRunButton(i),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: _showOtherRunsDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceDark,
                      foregroundColor: AppTheme.textColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '...',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(int runs) {
    Color bgColor = Colors.green.shade700;

    return ElevatedButton(
      onPressed: () => _recordRuns(runs),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        runs.toString(),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _retireBatsman() {
    if (_striker == null || _nonStriker == null) {
      _showError('Players not selected');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Retire Batsman',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Retire ${_striker!.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final retiredName = _striker!.name;
              setState(() {
                // Swap striker with non-striker
                final temp = _striker;
                _striker = _nonStriker;
                _nonStriker = temp;
              });
              Navigator.pop(context);
              _showError('$retiredName retired. ${_striker!.name} is new striker.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Retire'),
          ),
        ],
      ),
    );
  }

  void _showPartnerships() {
    if (_inning == null) {
      _showError('Match data not available');
      return;
    }

    int runs = 0;
    int balls = 0;
    
    for (var stat in _battingStats) {
      if (stat.playerId == _striker!.id || stat.playerId == _nonStriker!.id) {
        runs += stat.runs;
        balls += stat.ballsFaced;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Current Partnership',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_striker!.name} & ${_nonStriker!.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Runs: $runs | Balls: $balls',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Strike Rate: ${(runs / max(balls, 1) * 100).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGradientStart,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExtrasBreakdown() {
    if (_inning == null || _currentOverBalls.isEmpty) {
      _showError('No extras recorded yet');
      return;
    }

    int wides = 0;
    int noBalls = 0;
    int byes = 0;
    int legByes = 0;

    for (var ball in _currentOverBalls) {
      switch (ball.ballType) {
        case BallType.wide:
        case BallType.widePlusRuns:
          wides++;
          break;
        case BallType.noBall:
        case BallType.noBallPlusRuns:
          noBalls++;
          break;
        case BallType.bye:
          byes++;
          break;
        case BallType.legBye:
          legByes++;
          break;
        default:
          break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Extras Breakdown',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExtrasRow('Wides', wides),
            _buildExtrasRow('No Balls', noBalls),
            _buildExtrasRow('Byes', byes),
            _buildExtrasRow('Leg Byes', legByes),
            const Divider(color: Colors.grey),
            _buildExtrasRow(
              'Total Extras',
              wides + noBalls + byes + legByes,
              isTotal: true,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGradientStart,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasRow(String label, int count, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: isTotal ? Colors.green : Colors.grey,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showOtherRunsDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Enter Runs',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter run value (0-9)',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final runs = int.tryParse(controller.text) ?? 0;
              if (runs >= 0 && runs <= 9) {
                _recordRuns(runs);
                Navigator.pop(context);
              } else {
                _showError('Please enter a value between 0-9');
              }
              controller.dispose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showDetailedStats() {
    if (_inning == null) {
      _showError('Match data not available');
      return;
    }

    int totalWickets = _inning!.wickets;
    int totalRuns = _inning!.totalRuns;
    double overs = _inning!.overs;
    
    // Calculate extras
    int totalExtras = 0;
    for (var ball in _currentOverBalls) {
      totalExtras += ball.extras;
    }

    // Calculate boundaries
    int fours = 0;
    int sixes = 0;
    for (var stat in _battingStats) {
      fours += stat.fours;
      sixes += stat.sixes;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Inning Statistics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total Runs', totalRuns.toString()),
              _buildStatRow('Wickets', totalWickets.toString()),
              _buildStatRow('Overs', overs.toStringAsFixed(1)),
              const Divider(color: Colors.grey),
              _buildStatRow('Boundaries', '${fours}x4 ${sixes}x6'),
              _buildStatRow('Total Extras', totalExtras.toString()),
              _buildStatRow('Run Rate', (_cricketService.calculateRunRate(totalRuns, overs)).toStringAsFixed(2)),
              const Divider(color: Colors.grey),
              _buildStatRow('Batsmen', _battingStats.length.toString()),
              _buildStatRow('Bowlers', _bowlingStats.length.toString()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Scorer',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (_battingStats.isNotEmpty)
                      Text(
                        '${_battingStats.first.playerName} (${_battingStats.first.runs})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const Text(
                        'No batsmen yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGradientStart,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _saveAndExit() async {
    if (_inning == null) {
      _showError('No data to save');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text(
                'Saving inning...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Save the inning data
      await _cricketService.updateInning(_inning!);

      // Pop the loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inning saved successfully'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );

      // Pop the cricket scoring screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      // Pop the loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showError('Failed to save inning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Cricket - Live Scoring'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showDetailedStats,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndExit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inning == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load match data',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please go back and try again',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildScoreHeader(),
                      const SizedBox(height: 16),
                      _buildBattingScorecard(),
                      _buildCurrentOver(),
                      _buildScoringOptions(),
                      _buildRunButtons(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
