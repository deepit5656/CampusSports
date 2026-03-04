import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_model.dart';
import '../models/match_model.dart';

class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a tournament and auto-generate matches based on format
  Future<TournamentModel> createTournament(TournamentModel tournament) async {
    final docRef = _firestore.collection('tournaments').doc(tournament.id);
    await docRef.set(tournament.toMap());

    // Generate matches based on format
    switch (tournament.format) {
      case TournamentFormat.roundRobin:
        await _generateRoundRobinMatches(tournament);
        break;
      case TournamentFormat.knockout:
        await _generateKnockoutMatches(tournament);
        break;
      case TournamentFormat.groupStage:
        await _generateGroupStageMatches(tournament);
        break;
    }

    return tournament;
  }

  /// Round-robin: every team plays every other team once
  Future<void> _generateRoundRobinMatches(TournamentModel tournament) async {
    final teams = tournament.teamIds;
    final matches = <Map<String, dynamic>>[];
    int roundNumber = 0;

    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        roundNumber++;
        final matchId = _firestore.collection('matches').doc().id;
        final matchDate = tournament.startDate.add(Duration(days: (roundNumber ~/ 4)));

        matches.add({
          'id': matchId,
          'sportId': tournament.sportId,
          'team1Id': teams[i],
          'team2Id': teams[j],
          'dateTime': Timestamp.fromDate(matchDate),
          'venue': tournament.venue ?? 'TBD',
          'status': 'upcoming',
          'category': tournament.category,
          'tournamentId': tournament.id,
          'round': roundNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Batch write all matches
    final batch = _firestore.batch();
    for (final matchData in matches) {
      final docRef = _firestore.collection('matches').doc(matchData['id']);
      batch.set(docRef, matchData);
    }
    await batch.commit();
  }

  /// Knockout: single elimination bracket
  Future<void> _generateKnockoutMatches(TournamentModel tournament) async {
    final teams = tournament.teamIds;
    
    // Pad to nearest power of 2 with byes
    int bracketSize = 1;
    while (bracketSize < teams.length) {
      bracketSize *= 2;
    }

    final batch = _firestore.batch();
    int round = 1;
    int matchesInRound = bracketSize ~/ 2;
    int matchIndex = 0;

    // Generate first round matches (some may be byes)
    for (int i = 0; i < matchesInRound; i++) {
      final team1Index = i * 2;
      final team2Index = i * 2 + 1;

      // Skip if both slots would be byes
      if (team1Index >= teams.length) continue;

      final matchId = _firestore.collection('matches').doc().id;
      final matchDate = tournament.startDate.add(Duration(days: matchIndex ~/ 4));

      if (team2Index >= teams.length) {
        // Bye - team advances automatically (don't create match)
        continue;
      }

      final matchData = {
        'id': matchId,
        'sportId': tournament.sportId,
        'team1Id': teams[team1Index],
        'team2Id': teams[team2Index],
        'dateTime': Timestamp.fromDate(matchDate),
        'venue': tournament.venue ?? 'TBD',
        'status': 'upcoming',
        'category': tournament.category,
        'tournamentId': tournament.id,
        'round': round,
        'bracketPosition': i,
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(_firestore.collection('matches').doc(matchId), matchData);
      matchIndex++;
    }

    await batch.commit();
  }

  /// Group stage: divide teams into groups, round-robin within each group
  Future<void> _generateGroupStageMatches(TournamentModel tournament) async {
    final teams = List<String>.from(tournament.teamIds);
    final groupCount = tournament.groupCount ?? 2;
    
    // Distribute teams into groups
    final groups = List.generate(groupCount, (_) => <String>[]);
    for (int i = 0; i < teams.length; i++) {
      groups[i % groupCount].add(teams[i]);
    }

    final batch = _firestore.batch();
    int matchNum = 0;

    for (int g = 0; g < groups.length; g++) {
      final groupTeams = groups[g];
      for (int i = 0; i < groupTeams.length; i++) {
        for (int j = i + 1; j < groupTeams.length; j++) {
          matchNum++;
          final matchId = _firestore.collection('matches').doc().id;
          final matchDate = tournament.startDate.add(Duration(days: matchNum ~/ 4));

          final matchData = {
            'id': matchId,
            'sportId': tournament.sportId,
            'team1Id': groupTeams[i],
            'team2Id': groupTeams[j],
            'dateTime': Timestamp.fromDate(matchDate),
            'venue': tournament.venue ?? 'TBD',
            'status': 'upcoming',
            'category': tournament.category,
            'tournamentId': tournament.id,
            'round': matchNum,
            'group': 'Group ${String.fromCharCode(65 + g)}', // A, B, C...
            'createdAt': FieldValue.serverTimestamp(),
          };

          batch.set(_firestore.collection('matches').doc(matchId), matchData);
        }
      }
    }

    await batch.commit();
  }

  /// Get all tournaments
  Stream<List<TournamentModel>> getTournaments() {
    return _firestore
        .collection('tournaments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentModel.fromSnapshot(doc))
            .toList());
  }

  /// Get matches for a tournament
  Stream<List<MatchModel>> getTournamentMatches(String tournamentId) {
    return _firestore
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('round')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromSnapshot(doc))
            .toList());
  }

  /// Delete tournament and its matches
  Future<void> deleteTournament(String tournamentId) async {
    // Delete matches
    final matches = await _firestore
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();

    final batch = _firestore.batch();
    for (final doc in matches.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('tournaments').doc(tournamentId));
    await batch.commit();
  }

  /// Get tournament match stats
  Future<Map<String, int>> getTournamentStats(String tournamentId) async {
    final matches = await _firestore
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();

    int total = matches.docs.length;
    int completed = matches.docs.where((d) => d.data()['status'] == 'completed').length;
    int upcoming = matches.docs.where((d) => d.data()['status'] == 'upcoming').length;
    int live = matches.docs.where((d) => d.data()['status'] == 'live').length;

    return {
      'total': total,
      'completed': completed,
      'upcoming': upcoming,
      'live': live,
    };
  }
}
