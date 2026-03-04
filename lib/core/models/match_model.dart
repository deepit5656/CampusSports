import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'team_score_model.dart';

class MatchModel extends Equatable {
  final String id;
  final String sportId;
  final String team1Id;
  final String team2Id;
  final DateTime dateTime;
  final String venue;
  final String status; // upcoming, live, completed, cancelled
  final String? category; // Boys, Girls, Faculty
  
  // Legacy fields for backward compatibility
  final Map<String, dynamic>? result;
  final Map<String, int>? score;
  
  // New flexible scoring system
  final Map<String, TeamScore>? detailedScore;
  
  final String? winnerId;
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.sportId,
    required this.team1Id,
    required this.team2Id,
    required this.dateTime,
    required this.venue,
    required this.status,
    this.category,
    this.result,
    this.score,
    this.detailedScore,
    this.winnerId,
    required this.createdAt,
  });

  // Helper methods
  bool get hasDetailedScore => detailedScore != null && detailedScore!.isNotEmpty;
  
  TeamScore? getTeamScore(String teamId) {
    return detailedScore?[teamId];
  }

  // Get formatted score for display (handles both legacy and new format)
  String getFormattedScore(String teamId, String primaryField, [String? secondaryField]) {
    if (hasDetailedScore) {
      final teamScore = detailedScore![teamId];
      if (teamScore != null) {
        return teamScore.getFormattedScore(primaryField, secondaryField);
      }
    }
    
    // Fallback to legacy score
    if (score != null && score!.containsKey(teamId)) {
      return score![teamId].toString();
    }
    
    return '0';
  }

  // Check if match has scores (either format)
  bool get hasScores => hasDetailedScore || (score != null && score!.isNotEmpty);

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? detailedScoreMap;
    if (detailedScore != null) {
      detailedScoreMap = {};
      detailedScore!.forEach((teamId, teamScore) {
        detailedScoreMap![teamId] = teamScore.toMap();
      });
    }

    return {
      'id': id,
      'sportId': sportId,
      'team1Id': team1Id,
      'team2Id': team2Id,
      'dateTime': Timestamp.fromDate(dateTime),
      'venue': venue,
      'status': status,
      'category': category,
      'result': result,
      'score': score,
      'detailedScore': detailedScoreMap,
      'winnerId': winnerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    Map<String, TeamScore>? detailedScoreMap;
    if (map['detailedScore'] != null) {
      detailedScoreMap = {};
      final scoreData = map['detailedScore'] as Map<String, dynamic>;
      scoreData.forEach((teamId, teamScoreData) {
        detailedScoreMap![teamId] = TeamScore.fromMap(teamScoreData);
      });
    }

    return MatchModel(
      id: map['id'] ?? '',
      sportId: map['sportId'] ?? '',
      team1Id: map['team1Id'] ?? '',
      team2Id: map['team2Id'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      venue: map['venue'] ?? '',
      status: map['status'] ?? 'upcoming',
      category: map['category'],
      result: map['result'] != null ? Map<String, dynamic>.from(map['result']) : null,
      score: map['score'] != null ? Map<String, int>.from(map['score']) : null,
      detailedScore: detailedScoreMap,
      winnerId: map['winnerId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory MatchModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return MatchModel.fromMap(data);
  }

  bool get isUpcoming => status == 'upcoming';
  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  MatchModel copyWith({
    String? id,
    String? sportId,
    String? team1Id,
    String? team2Id,
    DateTime? dateTime,
    String? venue,
    String? status,
    String? category,
    Map<String, dynamic>? result,
    Map<String, int>? score,
    Map<String, TeamScore>? detailedScore,
    String? winnerId,
    DateTime? createdAt,
  }) {
    return MatchModel(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      dateTime: dateTime ?? this.dateTime,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      category: category ?? this.category,
      result: result ?? this.result,
      score: score ?? this.score,
      detailedScore: detailedScore ?? this.detailedScore,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sportId,
        team1Id,
        team2Id,
        dateTime,
        venue,
        status,
        category,
        result,
        score,
        detailedScore,
        winnerId,
        createdAt,
      ];
}
