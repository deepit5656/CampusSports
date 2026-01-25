import 'package:equatable/equatable.dart';

class ScoringConfig extends Equatable {
  final String scoreType; // 'runs', 'goals', 'points', 'sets'
  final List<ScoreField> scoreFields;
  final String? winCondition; // 'highest', 'lowest', 'best_of'
  final Map<String, dynamic>? additionalConfig;

  const ScoringConfig({
    required this.scoreType,
    required this.scoreFields,
    this.winCondition,
    this.additionalConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'scoreType': scoreType,
      'scoreFields': scoreFields.map((field) => field.toMap()).toList(),
      'winCondition': winCondition,
      'additionalConfig': additionalConfig,
    };
  }

  factory ScoringConfig.fromMap(Map<String, dynamic> map) {
    return ScoringConfig(
      scoreType: map['scoreType'] ?? 'points',
      scoreFields: (map['scoreFields'] as List<dynamic>?)
              ?.map((field) => ScoreField.fromMap(field as Map<String, dynamic>))
              .toList() ??
          [],
      winCondition: map['winCondition'],
      additionalConfig: map['additionalConfig'] != null
          ? Map<String, dynamic>.from(map['additionalConfig'])
          : null,
    );
  }

  ScoringConfig copyWith({
    String? scoreType,
    List<ScoreField>? scoreFields,
    String? winCondition,
    Map<String, dynamic>? additionalConfig,
  }) {
    return ScoringConfig(
      scoreType: scoreType ?? this.scoreType,
      scoreFields: scoreFields ?? this.scoreFields,
      winCondition: winCondition ?? this.winCondition,
      additionalConfig: additionalConfig ?? this.additionalConfig,
    );
  }

  // Basic constructor for simple sports
  factory ScoringConfig.basic() {
    return const ScoringConfig(
      scoreType: 'points',
      scoreFields: [
        ScoreField(
          id: 'points',
          name: 'Points',
          type: 'number',
          isPrimary: true,
          showInCard: true,
          minValue: 0,
          unit: 'points',
          displayOrder: 0,
        ),
      ],
      winCondition: 'highest',
    );
  }

  @override
  List<Object?> get props => [scoreType, scoreFields, winCondition, additionalConfig];
}

class ScoreField extends Equatable {
  final String id; // Unique field identifier
  final String name; // Display name (e.g., "Runs", "Wickets")
  final String type; // 'number', 'timer', 'percentage'
  final bool isPrimary; // Main score field
  final bool showInCard; // Display on match cards
  final int? minValue;
  final int? maxValue;
  final String? unit; // Optional unit (e.g., "runs", "goals")
  final int displayOrder; // Order in which to display

  const ScoreField({
    required this.id,
    required this.name,
    required this.type,
    required this.isPrimary,
    required this.showInCard,
    this.minValue,
    this.maxValue,
    this.unit,
    required this.displayOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isPrimary': isPrimary,
      'showInCard': showInCard,
      'minValue': minValue,
      'maxValue': maxValue,
      'unit': unit,
      'displayOrder': displayOrder,
    };
  }

  factory ScoreField.fromMap(Map<String, dynamic> map) {
    return ScoreField(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'number',
      isPrimary: map['isPrimary'] ?? false,
      showInCard: map['showInCard'] ?? true,
      minValue: map['minValue'],
      maxValue: map['maxValue'],
      unit: map['unit'],
      displayOrder: map['displayOrder'] ?? 0,
    );
  }

  ScoreField copyWith({
    String? id,
    String? name,
    String? type,
    bool? isPrimary,
    bool? showInCard,
    int? minValue,
    int? maxValue,
    String? unit,
    int? displayOrder,
  }) {
    return ScoreField(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isPrimary: isPrimary ?? this.isPrimary,
      showInCard: showInCard ?? this.showInCard,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      unit: unit ?? this.unit,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        isPrimary,
        showInCard,
        minValue,
        maxValue,
        unit,
        displayOrder,
      ];
}