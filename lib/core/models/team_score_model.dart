import 'package:equatable/equatable.dart';

class TeamScore extends Equatable {
  final String teamId;
  final Map<String, dynamic> scores; // Dynamic score fields
  final bool isWinner;

  const TeamScore({
    required this.teamId,
    required this.scores,
    required this.isWinner,
  });

  // Get primary score value
  dynamic getPrimaryScore(String primaryFieldId) {
    return scores[primaryFieldId];
  }

  // Get formatted score string for display
  String getFormattedScore(String primaryFieldId, String? secondaryFieldId) {
    final primary = scores[primaryFieldId];
    if (secondaryFieldId != null && scores.containsKey(secondaryFieldId)) {
      final secondary = scores[secondaryFieldId];
      return '$primary/$secondary';
    }
    return primary.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'scores': scores,
      'isWinner': isWinner,
    };
  }

  factory TeamScore.fromMap(Map<String, dynamic> map) {
    return TeamScore(
      teamId: map['teamId'] ?? '',
      scores: Map<String, dynamic>.from(map['scores'] ?? {}),
      isWinner: map['isWinner'] ?? false,
    );
  }

  TeamScore copyWith({
    String? teamId,
    Map<String, dynamic>? scores,
    bool? isWinner,
  }) {
    return TeamScore(
      teamId: teamId ?? this.teamId,
      scores: scores ?? this.scores,
      isWinner: isWinner ?? this.isWinner,
    );
  }

  @override
  List<Object?> get props => [teamId, scores, isWinner];
}