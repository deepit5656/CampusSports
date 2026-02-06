import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'scoring_config_model.dart';
import 'sport_templates.dart';
import 'team_score_model.dart';

class SportModel extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String description;
  final ScoringConfig scoringConfig;
  final DateTime createdAt;

  const SportModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.scoringConfig,
    required this.createdAt,
  });

  // Helper methods for scoring
  ScoreField get primaryScoreField {
    return scoringConfig.scoreFields.firstWhere(
      (field) => field.isPrimary,
      orElse: () => scoringConfig.scoreFields.first,
    );
  }

  List<ScoreField> get cardDisplayFields {
    return scoringConfig.scoreFields
        .where((field) => field.showInCard)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  List<ScoreField> get allFieldsSorted {
    return List.from(scoringConfig.scoreFields)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'scoringConfig': scoringConfig.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SportModel.fromMap(Map<String, dynamic> map) {
    return SportModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      description: map['description'] ?? '',
      scoringConfig: map['scoringConfig'] != null
          ? ScoringConfig.fromMap(map['scoringConfig'])
          : SportTemplate.getDefaultTemplate(),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory SportModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SportModel.fromMap(data);
  }

  // Format team score based on sport configuration
  ({String primary, String secondary}) getFormattedScore(TeamScore teamScore) {
    final primaryField = this.primaryScoreField;
    final cardFields = cardDisplayFields;
    
    // Primary score (always shown)
    final primaryValue = teamScore.scores[primaryField.id]?.toString() ?? '0';
    String primaryScore = primaryValue;
    
    // Add unit if available
    if (primaryField.unit != null && primaryField.unit!.isNotEmpty) {
      primaryScore = '$primaryValue ${primaryField.unit}';
    }
    
    // Secondary score (additional info)
    String secondaryScore = '';
    
    if (cardFields.length > 1) {
      final secondaryFields = cardFields.where((f) => !f.isPrimary).take(2).toList();
      if (secondaryFields.isNotEmpty) {
        final secondaryValues = secondaryFields.map((field) {
          final value = teamScore.scores[field.id]?.toString() ?? '0';
          final unit = field.unit ?? field.name.toLowerCase();
          return '$value $unit';
        }).join(', ');
        secondaryScore = '($secondaryValues)';
      }
    }
    
    return (primary: primaryScore, secondary: secondaryScore);
  }

  SportModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    ScoringConfig? scoringConfig,
    DateTime? createdAt,
  }) {
    return SportModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      scoringConfig: scoringConfig ?? this.scoringConfig,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, description, scoringConfig, createdAt];
}
