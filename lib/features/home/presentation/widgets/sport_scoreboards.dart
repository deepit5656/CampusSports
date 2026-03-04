import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';

/// Main dispatcher — detects sport type and shows the proper scoreboard
class SportScoreboard extends StatelessWidget {
  final String sportName;
  final Map<String, dynamic> matchData; // raw Firestore document data
  final String matchId;
  final String team1Id;
  final String team2Id;
  final String team1Name;
  final String team2Name;

  const SportScoreboard({
    super.key,
    required this.sportName,
    required this.matchData,
    required this.matchId,
    required this.team1Id,
    required this.team2Id,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final sport = sportName.toLowerCase().trim();

    if (sport == 'football' && matchData['footballMatchData'] != null) {
      return FootballScoreboard(
        data: Map<String, dynamic>.from(matchData['footballMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
        team1Id: team1Id,
        team2Id: team2Id,
      );
    }
    if (sport == 'basketball' && matchData['basketballMatchData'] != null) {
      return BasketballScoreboard(
        data: Map<String, dynamic>.from(matchData['basketballMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
        team1Id: team1Id,
        team2Id: team2Id,
      );
    }
    if (sport == 'tennis' && matchData['tennisMatchData'] != null) {
      return TennisScoreboard(
        data: Map<String, dynamic>.from(matchData['tennisMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }
    if (sport == 'cricket') {
      return CricketScoreboard(
        matchData: matchData,
        matchId: matchId,
        team1Id: team1Id,
        team2Id: team2Id,
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }
    if (sport == 'badminton' && matchData['badmintonMatchData'] != null) {
      return BadmintonScoreboard(
        data: Map<String, dynamic>.from(matchData['badmintonMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }
    if (sport == 'volleyball' && matchData['volleyballMatchData'] != null) {
      return VolleyballScoreboard(
        data: Map<String, dynamic>.from(matchData['volleyballMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }
    if ((sport == 'table tennis' || sport == 'tabletennis') &&
        matchData['tableTennisMatchData'] != null) {
      return TableTennisScoreboard(
        data: Map<String, dynamic>.from(matchData['tableTennisMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }
    if (sport == 'kabaddi' && matchData['kabaddiMatchData'] != null) {
      return KabaddiScoreboard(
        data: Map<String, dynamic>.from(matchData['kabaddiMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }
    if ((sport == 'tug of war' || sport == 'tugofwar') &&
        matchData['tugOfWarMatchData'] != null) {
      return TugOfWarScoreboard(
        data: Map<String, dynamic>.from(matchData['tugOfWarMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }
    if (sport == 'frisbee' && matchData['frisbeeMatchData'] != null) {
      return FrisbeeScoreboard(
        data: Map<String, dynamic>.from(matchData['frisbeeMatchData']),
        team1Name: team1Name,
        team2Name: team2Name,
      );
    }

    // No sport-specific data available
    return const SizedBox.shrink();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ──────────────────────────────────────────────────────────────────────────────

class _ScoreboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ScoreboardCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Reusable set/quarter score table
class _PeriodScoreTable extends StatelessWidget {
  final String periodLabel; // "Set", "Quarter", "Half"
  final List<String> periodKeys; // e.g. ['1','2','3']
  final Map<String, dynamic> periodScores; // from Firestore
  final String team1Name;
  final String team2Name;
  final int? team1Total;
  final int? team2Total;

  const _PeriodScoreTable({
    required this.periodLabel,
    required this.periodKeys,
    required this.periodScores,
    required this.team1Name,
    required this.team2Name,
    this.team1Total,
    this.team2Total,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: {
        0: const FlexColumnWidth(2.5),
        for (int i = 0; i < periodKeys.length; i++)
          i + 1: const FlexColumnWidth(1),
        if (team1Total != null) periodKeys.length + 1: const FlexColumnWidth(1.2),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          children: [
            _headerCell('Team'),
            for (var key in periodKeys) _headerCell('$periodLabel $key'),
            if (team1Total != null) _headerCell('Total'),
          ],
        ),
        // Team 1 row
        _teamRow(
          team1Name,
          periodKeys.map((k) {
            final data = periodScores[k];
            if (data is Map) return (data['team1'] ?? 0).toString();
            return '0';
          }).toList(),
          team1Total,
        ),
        // Team 2 row
        _teamRow(
          team2Name,
          periodKeys.map((k) {
            final data = periodScores[k];
            if (data is Map) return (data['team2'] ?? 0).toString();
            return '0';
          }).toList(),
          team2Total,
        ),
      ],
    );
  }

  TableRow _teamRow(String name, List<String> scores, int? total) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (var s in scores)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(s, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
          ),
        if (total != null)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              total.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// FOOTBALL SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class FootballScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;
  final String team1Id;
  final String team2Id;

  const FootballScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
    required this.team1Id,
    required this.team2Id,
  });

  @override
  Widget build(BuildContext context) {
    final events = (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (events.isEmpty) return const SizedBox.shrink();

    final goals = events.where((e) => e['type'] == 'goal').toList();
    final yellowCards = events.where((e) => e['type'] == 'yellow_card').toList();
    final redCards = events.where((e) => e['type'] == 'red_card').toList();

    return _ScoreboardCard(
      title: 'Football Match Details',
      icon: Icons.sports_soccer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goals timeline
          if (goals.isNotEmpty) ...[
            _sectionTitle('Goals'),
            const SizedBox(height: 8),
            ...goals.map((g) => _eventTile(
                  icon: Icons.sports_soccer,
                  iconColor: Colors.white,
                  minute: g['minute'],
                  player: g['player'] ?? 'Unknown',
                  team: g['team'] ?? '',
                  teamId: g['teamId'],
                )),
          ],

          // Yellow cards
          if (yellowCards.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Yellow Cards'),
            const SizedBox(height: 8),
            ...yellowCards.map((c) => _eventTile(
                  icon: Icons.square,
                  iconColor: Colors.yellow.shade700,
                  minute: c['minute'],
                  player: c['player'] ?? 'Unknown',
                  team: c['team'] ?? '',
                  teamId: c['teamId'],
                )),
          ],

          // Red cards
          if (redCards.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Red Cards'),
            const SizedBox(height: 8),
            ...redCards.map((c) => _eventTile(
                  icon: Icons.square,
                  iconColor: Colors.red,
                  minute: c['minute'],
                  player: c['player'] ?? 'Unknown',
                  team: c['team'] ?? '',
                  teamId: c['teamId'],
                )),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _eventTile({
    required IconData icon,
    required Color iconColor,
    int? minute,
    required String player,
    required String team,
    String? teamId,
  }) {
    final isTeam1 = teamId == team1Id || team == team1Name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              minute != null ? "$minute'" : '—',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.primaryGradientStart,
              ),
            ),
          ),
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isTeam1
                  ? AppTheme.primaryGradientStart.withOpacity(0.15)
                  : AppTheme.accentGradientStart.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isTeam1 ? team1Name : team2Name,
              style: TextStyle(
                fontSize: 11,
                color: isTeam1 ? AppTheme.primaryGradientStart : AppTheme.accentGradientStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BASKETBALL SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class BasketballScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;
  final String team1Id;
  final String team2Id;

  const BasketballScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
    required this.team1Id,
    required this.team2Id,
  });

  @override
  Widget build(BuildContext context) {
    final quarterScores =
        (data['quarterScores'] as Map<String, dynamic>?) ?? {};
    if (quarterScores.isEmpty) return const SizedBox.shrink();

    final keys = quarterScores.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    int t1Total = 0, t2Total = 0;
    for (var k in keys) {
      final qs = quarterScores[k] as Map<String, dynamic>? ?? {};
      t1Total += (qs['team1'] ?? 0) as int;
      t2Total += (qs['team2'] ?? 0) as int;
    }

    final events = (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final fouls = events.where((e) => e['type'] == 'foul').toList();

    return _ScoreboardCard(
      title: 'Quarter Scores',
      icon: Icons.sports_basketball,
      child: Column(
        children: [
          _PeriodScoreTable(
            periodLabel: 'Q',
            periodKeys: keys,
            periodScores: quarterScores,
            team1Name: team1Name,
            team2Name: team2Name,
            team1Total: t1Total,
            team2Total: t2Total,
          ),
          if (fouls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fouls',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...fouls.map((f) => _foulTile(f)),
          ],
        ],
      ),
    );
  }

  Widget _foulTile(Map<String, dynamic> f) {
    final isTeam1 = f['teamId'] == team1Id || f['team'] == team1Name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppTheme.warningColor, size: 16),
          const SizedBox(width: 8),
          Text('Q${f['quarter'] ?? '?'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTeam1 ? team1Name : team2Name,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TENNIS SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class TennisScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;

  const TennisScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final setScores = (data['setScores'] as List?) ?? [];
    final t1Sets = (data['team1Sets'] ?? 0) as int;
    final t2Sets = (data['team2Sets'] ?? 0) as int;

    if (setScores.isEmpty) return const SizedBox.shrink();

    return _ScoreboardCard(
      title: 'Set Scores',
      icon: Icons.sports_tennis,
      child: Column(
        children: [
          // Set score grid
          Table(
            border: TableBorder.all(
              color: AppTheme.surfaceDark.withOpacity(0.5),
              width: 1,
              borderRadius: BorderRadius.circular(8),
            ),
            columnWidths: {
              0: const FlexColumnWidth(2.5),
              for (int i = 0; i < setScores.length; i++)
                i + 1: const FlexColumnWidth(1),
              setScores.length + 1: const FlexColumnWidth(1.2),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withOpacity(0.3),
                ),
                children: [
                  _cell('Team', bold: true, secondary: true),
                  for (int i = 0; i < setScores.length; i++)
                    _cell('Set ${i + 1}', bold: true, secondary: true),
                  _cell('Sets', bold: true, secondary: true),
                ],
              ),
              // Team 1
              TableRow(children: [
                _cell(team1Name, bold: true),
                for (var s in setScores)
                  _cell('${(s as Map?)?['team1'] ?? 0}'),
                _cell('$t1Sets', bold: true),
              ]),
              // Team 2
              TableRow(children: [
                _cell(team2Name, bold: true),
                for (var s in setScores)
                  _cell('${(s as Map?)?['team2'] ?? 0}'),
                _cell('$t2Sets', bold: true),
              ]),
            ],
          ),

          // Current set info if match is live
          if (data['isTiebreak'] == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, size: 16, color: AppTheme.warningColor),
                  const SizedBox(width: 4),
                  Text(
                    'Tiebreak: ${data['team1TiebreakPoints'] ?? 0} - ${data['team2TiebreakPoints'] ?? 0}',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false, bool secondary = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
          color: secondary ? AppTheme.textSecondary : null,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CRICKET SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class CricketScoreboard extends StatelessWidget {
  final Map<String, dynamic> matchData;
  final String matchId;
  final String team1Id;
  final String team2Id;
  final String team1Name;
  final String team2Name;

  const CricketScoreboard({
    super.key,
    required this.matchData,
    required this.matchId,
    required this.team1Id,
    required this.team2Id,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final cricketData = matchData['cricketMatchData'] != null
        ? Map<String, dynamic>.from(matchData['cricketMatchData'])
        : <String, dynamic>{};

    return _ScoreboardCard(
      title: 'Cricket Scorecard',
      icon: Icons.sports_cricket,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toss info
          if (cricketData['tossWonBy'] != null) ...[
            _infoChip(
              Icons.emoji_events,
              'Toss: ${cricketData['tossWonBy'] == 'host' ? team1Name : team2Name} '
                  '(elected to ${cricketData['optedTo'] ?? '?'})',
            ),
            const SizedBox(height: 8),
          ],

          // Overs
          if (cricketData['overs'] != null)
            _infoChip(Icons.timer, 'Overs: ${cricketData['overs']}'),

          const SizedBox(height: 12),

          // Live score from match_states collection
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('match_states')
                .doc(matchId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                // Show basic score from match doc
                return _basicScoreRow();
              }

              final stateData =
                  snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final currentScore =
                  (stateData['currentScore'] as Map<String, dynamic>?) ?? {};
              final currentInning = stateData['currentInning'] ?? 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Innings score summary
                  _inningsScoreCard(
                    team1Name,
                    (currentScore[team1Id] ?? 0).toString(),
                    team2Name,
                    (currentScore[team2Id] ?? 0).toString(),
                    currentInning,
                  ),
                  const SizedBox(height: 12),

                  // Ball-by-ball events
                  _buildEventsList(),
                ],
              );
            },
          ),

          // Result
          if (matchData['result'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.successGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (matchData['result'] as Map<String, dynamic>)['description'] ??
                    'Match completed',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _basicScoreRow() {
    final score = matchData['score'] as Map<String, dynamic>?;
    if (score == null) {
      return const Text('Score data not available yet',
          style: TextStyle(color: AppTheme.textSecondary));
    }
    return _inningsScoreCard(
      team1Name,
      (score[team1Id] ?? 0).toString(),
      team2Name,
      (score[team2Id] ?? 0).toString(),
      null,
    );
  }

  Widget _inningsScoreCard(
    String t1, String s1, String t2, String s2, int? currentInning,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (currentInning != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Innings $currentInning',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(t1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(s1,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: AppTheme.primaryGradientStart)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  shape: BoxShape.circle,
                ),
                child: const Text('vs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(t2,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(s2,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: AppTheme.accentGradientStart)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('match_states')
          .doc(matchId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final events = snapshot.data!.docs;

        // Group by over
        final Map<String, List<Map<String, dynamic>>> overGroups = {};
        for (var doc in events) {
          final e = doc.data() as Map<String, dynamic>;
          final overNum = e['overNumber'] ?? 0;
          final inning = e['inningNumber'] ?? 1;
          final key = 'Inn $inning - Over $overNum';
          overGroups.putIfAbsent(key, () => []);
          overGroups[key]!.add(e);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Balls',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...overGroups.entries.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primaryGradientStart)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: entry.value.reversed.map((e) {
                        final eventData =
                            (e['eventData'] as Map<String, dynamic>?) ?? {};
                        final runs = eventData['value'] ?? 0;
                        final actionName =
                            eventData['actionName']?.toString() ?? '';

                        Color ballColor;
                        String label;
                        if (actionName.toLowerCase().contains('wicket')) {
                          ballColor = AppTheme.errorColor;
                          label = 'W';
                        } else if (actionName.toLowerCase().contains('wide')) {
                          ballColor = AppTheme.warningColor;
                          label = 'Wd';
                        } else if (actionName.toLowerCase().contains('no ball') ||
                            actionName.toLowerCase().contains('noball')) {
                          ballColor = AppTheme.warningColor;
                          label = 'Nb';
                        } else if (runs == 4) {
                          ballColor = AppTheme.successColor;
                          label = '4';
                        } else if (runs == 6) {
                          ballColor = AppTheme.primaryGradientStart;
                          label = '6';
                        } else if (runs == 0) {
                          ballColor = AppTheme.surfaceDark;
                          label = '0';
                        } else {
                          ballColor = AppTheme.textSecondary;
                          label = '$runs';
                        }

                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ballColor.withOpacity(0.2),
                            border: Border.all(color: ballColor, width: 1.5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: ballColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BADMINTON SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class BadmintonScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;

  const BadmintonScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final setScores = (data['setScores'] as Map<String, dynamic>?) ?? {};
    if (setScores.isEmpty) return const SizedBox.shrink();

    final keys = setScores.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final t1Won = (data['setsWonTeam1'] ?? 0) as int;
    final t2Won = (data['setsWonTeam2'] ?? 0) as int;

    return _ScoreboardCard(
      title: 'Badminton Set Scores',
      icon: Icons.sports,
      child: Column(
        children: [
          _PeriodScoreTable(
            periodLabel: 'Set',
            periodKeys: keys,
            periodScores: setScores,
            team1Name: team1Name,
            team2Name: team2Name,
            team1Total: t1Won,
            team2Total: t2Won,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _setsWonChip(team1Name, t1Won),
              const SizedBox(width: 16),
              _setsWonChip(team2Name, t2Won),
            ],
          ),
        ],
      ),
    );
  }

  Widget _setsWonChip(String name, int won) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: AppTheme.primaryGradientStart,
        child: Text('$won',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
      label: Text(name, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppTheme.surfaceDark.withOpacity(0.3),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// VOLLEYBALL SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class VolleyballScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;

  const VolleyballScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final setScores = (data['setScores'] as Map<String, dynamic>?) ?? {};
    if (setScores.isEmpty) return const SizedBox.shrink();

    final keys = setScores.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final t1Won = (data['team1SetsWon'] ?? 0) as int;
    final t2Won = (data['team2SetsWon'] ?? 0) as int;

    final events = (data['events'] as List?)?.cast<String>() ?? [];

    return _ScoreboardCard(
      title: 'Volleyball Set Scores',
      icon: Icons.sports_volleyball,
      child: Column(
        children: [
          _PeriodScoreTable(
            periodLabel: 'Set',
            periodKeys: keys,
            periodScores: setScores,
            team1Name: team1Name,
            team2Name: team2Name,
            team1Total: t1Won,
            team2Total: t2Won,
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Match Log',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: events.length > 10 ? 10 : events.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(events[events.length - 1 - i],
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TABLE TENNIS SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class TableTennisScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;

  const TableTennisScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final setScores = (data['setScores'] as Map<String, dynamic>?) ?? {};
    if (setScores.isEmpty) return const SizedBox.shrink();

    final keys = setScores.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final t1Won = (data['team1SetsWon'] ?? 0) as int;
    final t2Won = (data['team2SetsWon'] ?? 0) as int;

    return _ScoreboardCard(
      title: 'Table Tennis Set Scores',
      icon: Icons.sports,
      child: _PeriodScoreTable(
        periodLabel: 'Set',
        periodKeys: keys,
        periodScores: setScores,
        team1Name: team1Name,
        team2Name: team2Name,
        team1Total: t1Won,
        team2Total: t2Won,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// KABADDI SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class KabaddiScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;

  const KabaddiScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final t1Score = (data['team1Score'] ?? 0) as int;
    final t2Score = (data['team2Score'] ?? 0) as int;
    final events = (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Aggregate by type per team
    int t1Raids = 0, t2Raids = 0;
    int t1Tackles = 0, t2Tackles = 0;
    int t1Allouts = 0, t2Allouts = 0;
    for (var e in events) {
      final isT1 = e['team'] == 'team1';
      final pts = (e['points'] ?? 0) as int;
      switch (e['type']) {
        case 'raid':
          if (isT1) t1Raids += pts; else t2Raids += pts;
          break;
        case 'tackle':
          if (isT1) t1Tackles += pts; else t2Tackles += pts;
          break;
        case 'allout':
          if (isT1) t1Allouts += pts; else t2Allouts += pts;
          break;
      }
    }

    return _ScoreboardCard(
      title: 'Kabaddi Scorecard',
      icon: Icons.sports_kabaddi,
      child: Column(
        children: [
          // Score summary
          Table(
            border: TableBorder.all(
              color: AppTheme.surfaceDark.withOpacity(0.5),
              width: 1,
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withOpacity(0.3)),
                children: [
                  _cell('', bold: true),
                  _cell('Raids', bold: true, secondary: true),
                  _cell('Tackles', bold: true, secondary: true),
                  _cell('All-Outs', bold: true, secondary: true),
                  _cell('Total', bold: true, secondary: true),
                ],
              ),
              TableRow(children: [
                _cell(team1Name, bold: true),
                _cell('$t1Raids'),
                _cell('$t1Tackles'),
                _cell('$t1Allouts'),
                _cell('$t1Score', bold: true),
              ]),
              TableRow(children: [
                _cell(team2Name, bold: true),
                _cell('$t2Raids'),
                _cell('$t2Tackles'),
                _cell('$t2Allouts'),
                _cell('$t2Score', bold: true),
              ]),
            ],
          ),

          // Recent events
          if (events.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Events',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 8),
            ...events.reversed.take(8).map((e) {
              final isT1 = e['team'] == 'team1';
              final icon = e['type'] == 'raid'
                  ? Icons.directions_run
                  : e['type'] == 'tackle'
                      ? Icons.shield
                      : Icons.whatshot;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: AppTheme.primaryGradientStart),
                    const SizedBox(width: 8),
                    Text(
                      '${e['type']?.toString().toUpperCase() ?? ''} +${e['points'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Half ${e['half'] ?? '?'}',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      isT1 ? team1Name : team2Name,
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false, bool secondary = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: secondary ? AppTheme.textSecondary : null,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TUG OF WAR SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class TugOfWarScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;

  const TugOfWarScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final t1Pulls = (data['team1Pulls'] ?? 0) as int;
    final t2Pulls = (data['team2Pulls'] ?? 0) as int;
    final currentPull = data['currentPull'];

    return _ScoreboardCard(
      title: 'Tug of War',
      icon: Icons.fitness_center,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _pullScore(team1Name, t1Pulls, AppTheme.primaryGradientStart),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('vs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Expanded(
                child: _pullScore(team2Name, t2Pulls, AppTheme.accentGradientStart),
              ),
            ],
          ),
          if (currentPull != null) ...[
            const SizedBox(height: 12),
            Text('Best of 3 — Pull $currentPull',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 8),
          // Draw pull indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              Color color;
              IconData icon;
              if (i < t1Pulls) {
                color = AppTheme.primaryGradientStart;
                icon = Icons.check_circle;
              } else if (i < t1Pulls + t2Pulls) {
                color = AppTheme.accentGradientStart;
                icon = Icons.check_circle;
              } else {
                color = AppTheme.surfaceDark;
                icon = Icons.circle_outlined;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(icon, color: color, size: 28),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _pullScore(String name, int pulls, Color color) {
    return Column(
      children: [
        Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text('$pulls',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 36, color: color)),
        Text('Pulls Won',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// FRISBEE SCOREBOARD
// ──────────────────────────────────────────────────────────────────────────────

class FrisbeeScoreboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String team1Name;
  final String team2Name;

  const FrisbeeScoreboard({
    super.key,
    required this.data,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context) {
    final t1 = (data['team1Score'] ?? 0) as int;
    final t2 = (data['team2Score'] ?? 0) as int;
    final target = (data['pointsToWinMatch'] ?? 15) as int;
    final turnovers = (data['turnovers'] ?? 0) as int;

    return _ScoreboardCard(
      title: 'Frisbee Scoreboard',
      icon: Icons.album,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _teamScore(team1Name, t1, AppTheme.primaryGradientStart)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  shape: BoxShape.circle,
                ),
                child: const Text('vs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Expanded(child: _teamScore(team2Name, t2, AppTheme.accentGradientStart)),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar to target
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Target: $target pts',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Text('Turnovers: $turnovers',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (t1 > t2 ? t1 : t2) / target.clamp(1, 100),
                  backgroundColor: AppTheme.surfaceDark.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(
                    t1 > t2
                        ? AppTheme.primaryGradientStart
                        : AppTheme.accentGradientStart,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamScore(String name, int score, Color color) {
    return Column(
      children: [
        Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text('$score',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 36, color: color)),
      ],
    );
  }
}
