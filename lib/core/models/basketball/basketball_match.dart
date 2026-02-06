import 'package:cloud_firestore/cloud_firestore.dart';

class BasketballMatch {
  final String id;
  final String sportId;
  final String team1Id;
  final String team1Name;
  final String team2Id;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final String status; // 'pending', 'ongoing', 'completed'
  final int currentQuarter; // 1, 2, 3, 4
  final int quarterDuration; // minutes per quarter (typically 12)
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;

  const BasketballMatch({
    required this.id,
    required this.sportId,
    required this.team1Id,
    required this.team1Name,
    required this.team2Id,
    required this.team2Name,
    this.team1Score = 0,
    this.team2Score = 0,
    this.status = 'pending',
    this.currentQuarter = 1,
    this.quarterDuration = 12,
    this.winnerId,
    required this.createdAt,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sportId': sportId,
      'team1Id': team1Id,
      'team1Name': team1Name,
      'team2Id': team2Id,
      'team2Name': team2Name,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'status': status,
      'currentQuarter': currentQuarter,
      'quarterDuration': quarterDuration,
      'winnerId': winnerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }

  factory BasketballMatch.fromMap(Map<String, dynamic> map) {
    return BasketballMatch(
      id: map['id'] ?? '',
      sportId: map['sportId'] ?? '',
      team1Id: map['team1Id'] ?? '',
      team1Name: map['team1Name'] ?? '',
      team2Id: map['team2Id'] ?? '',
      team2Name: map['team2Name'] ?? '',
      team1Score: map['team1Score'] ?? 0,
      team2Score: map['team2Score'] ?? 0,
      status: map['status'] ?? 'pending',
      currentQuarter: map['currentQuarter'] ?? 1,
      quarterDuration: map['quarterDuration'] ?? 12,
      winnerId: map['winnerId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
    );
  }

  BasketballMatch copyWith({
    String? id,
    String? sportId,
    String? team1Id,
    String? team1Name,
    String? team2Id,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    String? status,
    int? currentQuarter,
    int? quarterDuration,
    String? winnerId,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return BasketballMatch(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      team1Id: team1Id ?? this.team1Id,
      team1Name: team1Name ?? this.team1Name,
      team2Id: team2Id ?? this.team2Id,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      status: status ?? this.status,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      quarterDuration: quarterDuration ?? this.quarterDuration,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
