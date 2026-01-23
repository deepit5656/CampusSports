import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MatchModel extends Equatable {
  final String id;
  final String sportId;
  final String team1Id;
  final String team2Id;
  final DateTime dateTime;
  final String venue;
  final String status; // upcoming, live, completed, cancelled
  final String? category; // Boys, Girls, Faculty
  final Map<String, dynamic>? result;
  final Map<String, int>? score;
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
    this.winnerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
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
      'winnerId': winnerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
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
      winnerId: map['winnerId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory MatchModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
        winnerId,
        createdAt,
      ];
}
