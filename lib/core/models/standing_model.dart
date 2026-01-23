import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class StandingModel extends Equatable {
  final String id;
  final String sportId;
  final String teamId;
  final String category;
  final int played;
  final int won;
  final int lost;
  final int drawn;
  final int points;
  final int goalsFor;
  final int goalsAgainst;
  final DateTime updatedAt;

  const StandingModel({
    required this.id,
    required this.sportId,
    required this.teamId,
    this.category = 'Boys',
    required this.played,
    required this.won,
    required this.lost,
    required this.drawn,
    required this.points,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.updatedAt,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sportId': sportId,
      'teamId': teamId,
      'category': category,
      'played': played,
      'won': won,
      'lost': lost,
      'drawn': drawn,
      'points': points,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory StandingModel.fromMap(Map<String, dynamic> map) {
    return StandingModel(
      id: map['id'] ?? '',
      sportId: map['sportId'] ?? '',
      teamId: map['teamId'] ?? '',
      category: map['category'] ?? 'Boys',
      played: map['played'] ?? 0,
      won: map['won'] ?? 0,
      lost: map['lost'] ?? 0,
      drawn: map['drawn'] ?? 0,
      points: map['points'] ?? 0,
      goalsFor: map['goalsFor'] ?? 0,
      goalsAgainst: map['goalsAgainst'] ?? 0,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory StandingModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StandingModel.fromMap(data);
  }

  StandingModel copyWith({
    String? id,
    String? sportId,
    String? teamId,
    String? category,
    int? played,
    int? won,
    int? lost,
    int? drawn,
    int? points,
    int? goalsFor,
    int? goalsAgainst,
    DateTime? updatedAt,
  }) {
    return StandingModel(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      teamId: teamId ?? this.teamId,
      category: category ?? this.category,
      played: played ?? this.played,
      won: won ?? this.won,
      lost: lost ?? this.lost,
      drawn: drawn ?? this.drawn,
      points: points ?? this.points,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sportId,
        teamId,
        category,
        played,
        won,
        lost,
        drawn,
        points,
        goalsFor,
        goalsAgainst,
        updatedAt,
      ];
}
