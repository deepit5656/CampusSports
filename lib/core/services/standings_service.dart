import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/standing_model.dart';

class StandingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update standings for a specific sport (for all categories)
  Future<void> updateStandingsForSport(String sportId, {String? category}) async {
    try {
      // Get all completed matches for this sport
      Query query = _firestore
          .collection('matches')
          .where('sportId', isEqualTo: sportId)
          .where('status', isEqualTo: 'completed');
      
      // Filter by category if provided
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      final matchesSnapshot = await query.get();

      if (matchesSnapshot.docs.isEmpty) {
        print('No completed matches found for sport: $sportId' + 
            (category != null ? ' in $category category' : ''));
        return;
      }

      final matches = matchesSnapshot.docs
          .map((doc) => MatchModel.fromSnapshot(doc))
          .toList();

      // Get all teams in this sport
      final teamsInMatches = <String>{};
      for (var match in matches) {
        teamsInMatches.add(match.team1Id);
        teamsInMatches.add(match.team2Id);
      }

      // Get category from first match (or default to 'Boys')
      final matchCategory = category ?? matches.first.category ?? 'Boys';

      // Calculate standings for each team
      final Map<String, Map<String, dynamic>> teamStats = {};

      for (var teamId in teamsInMatches) {
        teamStats[teamId] = {
          'played': 0,
          'won': 0,
          'lost': 0,
          'drawn': 0,
          'points': 0,
          'goalsFor': 0,
          'goalsAgainst': 0,
        };
      }

      // Process each match
      for (var match in matches) {
        if (match.score == null || match.score!.isEmpty) continue;

        final team1Score = match.score![match.team1Id] ?? 0;
        final team2Score = match.score![match.team2Id] ?? 0;

        // Update played
        teamStats[match.team1Id]!['played'] = 
            (teamStats[match.team1Id]!['played'] ?? 0) + 1;
        teamStats[match.team2Id]!['played'] = 
            (teamStats[match.team2Id]!['played'] ?? 0) + 1;

        // Update goals
        teamStats[match.team1Id]!['goalsFor'] = 
            (teamStats[match.team1Id]!['goalsFor'] ?? 0) + team1Score;
        teamStats[match.team1Id]!['goalsAgainst'] = 
            (teamStats[match.team1Id]!['goalsAgainst'] ?? 0) + team2Score;
        teamStats[match.team2Id]!['goalsFor'] = 
            (teamStats[match.team2Id]!['goalsFor'] ?? 0) + team2Score;
        teamStats[match.team2Id]!['goalsAgainst'] = 
            (teamStats[match.team2Id]!['goalsAgainst'] ?? 0) + team1Score;

        // Determine winner
        if (team1Score > team2Score) {
          // Team 1 wins
          teamStats[match.team1Id]!['won'] = 
              (teamStats[match.team1Id]!['won'] ?? 0) + 1;
          teamStats[match.team1Id]!['points'] = 
              (teamStats[match.team1Id]!['points'] ?? 0) + 3;
          teamStats[match.team2Id]!['lost'] = 
              (teamStats[match.team2Id]!['lost'] ?? 0) + 1;
        } else if (team2Score > team1Score) {
          // Team 2 wins
          teamStats[match.team2Id]!['won'] = 
              (teamStats[match.team2Id]!['won'] ?? 0) + 1;
          teamStats[match.team2Id]!['points'] = 
              (teamStats[match.team2Id]!['points'] ?? 0) + 3;
          teamStats[match.team1Id]!['lost'] = 
              (teamStats[match.team1Id]!['lost'] ?? 0) + 1;
        } else {
          // Draw
          teamStats[match.team1Id]!['drawn'] = 
              (teamStats[match.team1Id]!['drawn'] ?? 0) + 1;
          teamStats[match.team1Id]!['points'] = 
              (teamStats[match.team1Id]!['points'] ?? 0) + 1;
          teamStats[match.team2Id]!['drawn'] = 
              (teamStats[match.team2Id]!['drawn'] ?? 0) + 1;
          teamStats[match.team2Id]!['points'] = 
              (teamStats[match.team2Id]!['points'] ?? 0) + 1;
        }
      }

      // Save standings to Firestore
      final batch = _firestore.batch();

      for (var entry in teamStats.entries) {
        final teamId = entry.key;
        final stats = entry.value;

        // Check if standing exists
        final existingStanding = await _firestore
            .collection('standings')
            .where('sportId', isEqualTo: sportId)
            .where('teamId', isEqualTo: teamId)
            .limit(1)
            .get();

        DocumentReference standingRef;

        if (existingStanding.docs.isNotEmpty) {
          standingRef = existingStanding.docs.first.reference;
        } else {
          standingRef = _firestore.collection('standings').doc();
        }

        final standing = StandingModel(
          id: standingRef.id,
          sportId: sportId,
          teamId: teamId,
          category: matchCategory,
          played: stats['played']!,
          won: stats['won']!,
          lost: stats['lost']!,
          drawn: stats['drawn']!,
          points: stats['points']!,
          goalsFor: stats['goalsFor']!,
          goalsAgainst: stats['goalsAgainst']!,
          updatedAt: DateTime.now(),
        );

        batch.set(standingRef, standing.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      print('Standings updated successfully for sport: $sportId');
    } catch (e) {
      print('Error updating standings: $e');
      rethrow;
    }
  }

  /// Update standings when a match is completed
  Future<void> onMatchCompleted(MatchModel match) async {
    try {
      // Update standings for the specific category of this match
      final category = match.category ?? 'Boys';
      await updateStandingsForSport(match.sportId, category: category);
      print('Standings updated for match completion: ${match.id}');
    } catch (e) {
      print('Error updating standings after match completion: $e');
      rethrow;
    }
  }
}
