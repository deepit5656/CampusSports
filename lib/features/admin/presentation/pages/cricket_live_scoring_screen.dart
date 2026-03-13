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
  final List<CricketPlayer> batsmenList; // Batting team players
  final List<CricketPlayer> bowlersList; // Bowling team players

  const CricketLiveScoringScreen({
    Key? key,
    required this.matchId,
    required this.inningId,
    required this.config,
    required this.batsmenList,
    required this.bowlersList,
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
  
  int _batsmenIndex = 0; // Track next batsman to come
  int _bowlerIndex = 0; // Track batsmen who haven't bowled

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

      // Auto-select players from provided lists
      CricketPlayer? striker = widget.batsmenList.isNotEmpty ? widget.batsmenList[0] : null;
      CricketPlayer? nonStriker = widget.batsmenList.length > 1 ? widget.batsmenList[1] : null;
      CricketPlayer? bowler = widget.bowlersList.isNotEmpty ? widget.bowlersList[0] : null;

      // If inning has stored players, use them
      if (inning?.currentStrikerId != null && widget.batsmenList.isNotEmpty) {
        striker = widget.batsmenList.firstWhere(
          (p) => p.id == inning!.currentStrikerId,
          orElse: () => widget.batsmenList[0],
        );
      }
      if (inning?.currentNonStrikerId != null && widget.batsmenList.length > 1) {
        nonStriker = widget.batsmenList.firstWhere(
          (p) => p.id == inning!.currentNonStrikerId,
          orElse: () => widget.batsmenList[1],
        );
      }
      if (inning?.currentBowlerId != null && widget.bowlersList.isNotEmpty) {
        bowler = widget.bowlersList.firstWhere(
          (p) => p.id == inning!.currentBowlerId,
          orElse: () => widget.bowlersList[0],
        );
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
      actualRuns = 0;
    } else if (_isNoBall) {
      ballType = runs > 0 ? BallType.noBallPlusRuns : BallType.noBall;
      extras = widget.config.noBallRuns;
      actualRuns = runs;
    } else if (_isBye) {
      ballType = BallType.bye;
      extras = runs;
      actualRuns = 0;
    } else if (_isLegBye) {
      ballType = BallType.legBye;
      extras = runs;
      actualRuns = 0;
    }

    int ballNumber = _currentOverBalls.length + 1;
    int overNumber = _inning!.overs.floor();

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

      // Handle wicket - show dialog to select new batsman
      if (_isWicket) {
        _showBatsmanSelectionDialog();
      }

      // Check for end of over
      final totalRuns = actualRuns + extras;
      final shouldSwap = (totalRuns % 2 == 1);
      final newOvers = _inning!.overs + (ball.isValidBall ? 0.1 : 0.0);
      final isOverComplete = _cricketService.isOverComplete(newOvers);

      if (shouldSwap && !isOverComplete) {
        final temp = _striker;
        setState(() {
          _striker = _nonStriker;
          _nonStriker = temp;
        });
      } else if (isOverComplete) {
        // Show bowler selection dialog for new over
        _showBowlerSelectionDialog();
        
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

  void _showBatsmanSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Player Out - Select Next Batsman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_striker!.name} is out',
                style: const TextStyle(color: Colors.orange, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...widget.batsmenList.map((player) {
                bool isPlaying = player.id == _striker!.id || player.id == _nonStriker!.id;
                bool isAlreadyOut = _battingStats.any((s) => s.playerId == player.id && s.isOut);
                
                if (isPlaying || isAlreadyOut) return SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _striker = player);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceDark,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(player.name),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showBowlerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Over Complete - Select Bowler',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.bowlersList.map((player) {
              bool isCurrent = player.id == _currentBowler!.id;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: isCurrent ? null : () {
                    setState(() => _currentBowler = player);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Colors.grey : AppTheme.surfaceDark,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(player.name),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
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

    final crr = _cricketService.calculateRunRate(_inning!.totalRuns, _inning!.overs);

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
            'Inning ${_inning!.inningNumber}, Over ${_inning!.overs.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_inning!.totalRuns}/${_inning!.wickets}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CRR',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildCurrentPlayers() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Players',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Striker *',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    Text(
                      _striker?.name ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Non-Striker',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    Text(
                      _nonStriker?.name ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  'Bowler:',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentBowler?.name ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            'This Over:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentOverBalls.isEmpty
                ? [
                    const Text(
                      'No balls recorded yet',
                      style: TextStyle(color: Colors.grey),
                    )
                  ]
                : _currentOverBalls.map((ball) => _buildBallChip(ball)).toList(),
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
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
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
    return ElevatedButton(
      onPressed: () => _recordRuns(runs),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showOtherRunsDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Enter Runs', style: TextStyle(color: Colors.white)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _retireBatsman() {
    if (_striker == null) {
      _showError('No batsman to retire');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Retire Batsman', style: TextStyle(color: Colors.white)),
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
                _striker = _nonStriker;
                _nonStriker = null;
              });
              Navigator.pop(context);
              _showError('$retiredName retired');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
              '${_striker!.name} * & ${_nonStriker!.name}',
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
              'Strike Rate: ${(runs / max(balls, 1) * 100).toStringAsFixed(2)}%',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGradientStart),
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

    int wides = 0, noBalls = 0, byes = 0, legByes = 0;

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
          children: [
            _buildExtrasRow('Wides', wides),
            _buildExtrasRow('No Balls', noBalls),
            _buildExtrasRow('Byes', byes),
            _buildExtrasRow('Leg Byes', legByes),
            const Divider(color: Colors.grey),
            _buildExtrasRow('Total', wides + noBalls + byes + legByes, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildExtrasRow(String label, int count, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            count.toString(),
            style: TextStyle(
              color: isTotal ? Colors.green : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedStats() {
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
            children: [
              _buildStatRow('Total Runs', _inning!.totalRuns.toString()),
              _buildStatRow('Wickets', _inning!.wickets.toString()),
              _buildStatRow('Overs', _inning!.overs.toStringAsFixed(1)),
              const Divider(color: Colors.grey),
              _buildStatRow('Batsmen', _battingStats.length.toString()),
              _buildStatRow('Bowlers', _bowlingStats.length.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text('Saving inning...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      await _cricketService.updateInning(_inning!);

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inning saved successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showError('Failed to save: $e');
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
          IconButton(icon: const Icon(Icons.analytics), onPressed: _showDetailedStats),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAndExit),
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
                      _buildCurrentPlayers(),
                      _buildCurrentOver(),
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _buildOptionChip('Wide', _isWide, () => setState(() => _isWide = !_isWide)),
                            _buildOptionChip('No Ball', _isNoBall, () => setState(() => _isNoBall = !_isNoBall)),
                            _buildOptionChip('Byes', _isBye, () => setState(() => _isBye = !_isBye)),
                            _buildOptionChip('Leg Byes', _isLegBye, () => setState(() => _isLegBye = !_isLegBye)),
                            _buildOptionChip('Wicket', _isWicket, () => setState(() => _isWicket = !_isWicket)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _retireBatsman,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                child: const Text('Retire'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _swapBatsmen,
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark),
                                child: const Text('Swap'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showPartnerships,
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark),
                                child: const Text('Partner'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showExtrasBreakdown,
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark),
                                child: const Text('Extras'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildRunButtons(),
                      const SizedBox(height: 16),
                    ],
                  ),
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
            color: selected ? Colors.green : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textColor,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
