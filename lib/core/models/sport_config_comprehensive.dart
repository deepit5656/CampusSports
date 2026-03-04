import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Enums for sport configuration
enum SportType { team, individual }
enum StructureType { timeBased, oversBased, setsBased, roundsBased, pointsBased }
enum WinCondition { highestScore, mostSetsWon, mostRoundsWon, targetReached }

// Supporting classes
class ScoreAction extends Equatable {
  final String id;
  final String name;
  final int value;
  final String category;
  final bool requiresPlayer;
  final Color? color;
  final int displayOrder;
  final bool endsPlay;

  const ScoreAction({
    required this.id,
    required this.name,
    required this.value,
    required this.category,
    this.requiresPlayer = false,
    this.color,
    required this.displayOrder,
    this.endsPlay = false,
  });

  @override
  List<Object?> get props => [id, name, value, category, requiresPlayer, color, displayOrder, endsPlay];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'value': value,
    'category': category,
    'requiresPlayer': requiresPlayer,
    'color': color?.value,
    'displayOrder': displayOrder,
    'endsPlay': endsPlay,
  };

  factory ScoreAction.fromMap(Map<String, dynamic> map) => ScoreAction(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    value: map['value'] ?? 0,
    category: map['category'] ?? '',
    requiresPlayer: map['requiresPlayer'] ?? false,
    color: map['color'] != null ? Color(map['color']) : null,
    displayOrder: map['displayOrder'] ?? 0,
    endsPlay: map['endsPlay'] ?? false,
  );
}

class QuickActionButton extends Equatable {
  final String actionId;
  final String label;
  final int position;
  final bool isPrimary;

  const QuickActionButton({
    required this.actionId,
    required this.label,
    required this.position,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [actionId, label, position, isPrimary];

  Map<String, dynamic> toMap() => {
    'actionId': actionId,
    'label': label,
    'position': position,
    'isPrimary': isPrimary,
  };

  factory QuickActionButton.fromMap(Map<String, dynamic> map) => QuickActionButton(
    actionId: map['actionId'] ?? '',
    label: map['label'] ?? '',
    position: map['position'] ?? 0,
    isPrimary: map['isPrimary'] ?? false,
  );
}

// Main Sport Configuration Model
class SportConfigModel extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool isDefault; // Cannot be deleted if true
  final SportType sportType;
  final StructureType structureType;
  
  // Match Structure Properties
  final int? duration; // minutes for time-based
  final int? overs; // for cricket
  final int? periods; // sets/rounds/halves
  final int? pointsToWin; // for point-based
  final bool hasBreaks;
  final int? breakDuration;
  
  // Player Configuration
  final int playingPlayers;
  final int? minPlayers;
  final int? maxPlayers;
  final bool allowSubstitutions;
  
  // Scoring System
  final String primaryScoreUnit;
  final List<ScoreAction> scoreActions;
  final WinCondition winCondition;
  final bool supportsTie;
  final bool trackIndividualStats;
  
  // Rules
  final bool hasFouls;
  final bool hasTimeouts;
  final bool hasExtras;
  final Map<String, dynamic> customRules;
  
  // UI Configuration
  final List<QuickActionButton> quickActions;
  final Color primaryColor;
  
  final DateTime createdAt;

  const SportConfigModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.isDefault,
    required this.sportType,
    required this.structureType,
    this.duration,
    this.overs,
    this.periods,
    this.pointsToWin,
    this.hasBreaks = false,
    this.breakDuration,
    required this.playingPlayers,
    this.minPlayers,
    this.maxPlayers,
    this.allowSubstitutions = true,
    required this.primaryScoreUnit,
    required this.scoreActions,
    required this.winCondition,
    required this.supportsTie,
    this.trackIndividualStats = true,
    required this.hasFouls,
    required this.hasTimeouts,
    required this.hasExtras,
    this.customRules = const {},
    required this.quickActions,
    required this.primaryColor,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, name, icon, description, isDefault, sportType, structureType,
    duration, overs, periods, pointsToWin, hasBreaks, breakDuration,
    playingPlayers, minPlayers, maxPlayers, allowSubstitutions,
    primaryScoreUnit, scoreActions, winCondition, supportsTie, trackIndividualStats,
    hasFouls, hasTimeouts, hasExtras, customRules, quickActions, primaryColor, createdAt,
  ];

  String getStructureDisplayText() {
    switch (structureType) {
      case StructureType.timeBased:
        return '${duration}min';
      case StructureType.oversBased:
        return '$overs Overs';
      case StructureType.setsBased:
        return 'Best of $periods';
      case StructureType.roundsBased:
        return '$periods Rounds';
      case StructureType.pointsBased:
        return 'First to $pointsToWin';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'isDefault': isDefault,
      'sportType': sportType.name,
      'structureType': structureType.name,
      'duration': duration,
      'overs': overs,
      'periods': periods,
      'pointsToWin': pointsToWin,
      'hasBreaks': hasBreaks,
      'breakDuration': breakDuration,
      'playingPlayers': playingPlayers,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'allowSubstitutions': allowSubstitutions,
      'primaryScoreUnit': primaryScoreUnit,
      'scoreActions': scoreActions.map((e) => e.toMap()).toList(),
      'winCondition': winCondition.name,
      'supportsTie': supportsTie,
      'trackIndividualStats': trackIndividualStats,
      'hasFouls': hasFouls,
      'hasTimeouts': hasTimeouts,
      'hasExtras': hasExtras,
      'customRules': customRules,
      'quickActions': quickActions.map((e) => e.toMap()).toList(),
      'primaryColor': primaryColor.value,
      'createdAt': Timestamp.fromDate(createdAt),
      // Bridge: include scoringConfig so SportModel.fromMap works on the same document
      'scoringConfig': toScoringConfigMap(),
    };
  }

  factory SportConfigModel.fromMap(Map<String, dynamic> map) {
    return SportConfigModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      description: map['description'] ?? '',
      isDefault: map['isDefault'] ?? false,
      sportType: SportType.values.firstWhere(
        (e) => e.name == map['sportType'],
        orElse: () => SportType.team,
      ),
      structureType: StructureType.values.firstWhere(
        (e) => e.name == map['structureType'],
        orElse: () => StructureType.timeBased,
      ),
      duration: map['duration'],
      overs: map['overs'],
      periods: map['periods'],
      pointsToWin: map['pointsToWin'],
      hasBreaks: map['hasBreaks'] ?? false,
      breakDuration: map['breakDuration'],
      playingPlayers: map['playingPlayers'] ?? 11,
      minPlayers: map['minPlayers'],
      maxPlayers: map['maxPlayers'],
      allowSubstitutions: map['allowSubstitutions'] ?? true,
      primaryScoreUnit: map['primaryScoreUnit'] ?? 'point',
      scoreActions: (map['scoreActions'] as List<dynamic>? ?? [])
          .map((e) => ScoreAction.fromMap(e as Map<String, dynamic>))
          .toList(),
      winCondition: WinCondition.values.firstWhere(
        (e) => e.name == map['winCondition'],
        orElse: () => WinCondition.highestScore,
      ),
      supportsTie: map['supportsTie'] ?? false,
      trackIndividualStats: map['trackIndividualStats'] ?? true,
      hasFouls: map['hasFouls'] ?? false,
      hasTimeouts: map['hasTimeouts'] ?? false,
      hasExtras: map['hasExtras'] ?? false,
      customRules: Map<String, dynamic>.from(map['customRules'] ?? {}),
      quickActions: (map['quickActions'] as List<dynamic>? ?? [])
          .map((e) => QuickActionButton.fromMap(e as Map<String, dynamic>))
          .toList(),
      primaryColor: Color(map['primaryColor'] ?? 0xFF2196F3),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Bridge method: generate a ScoringConfig from this comprehensive config.
  /// This allows SportModel.fromMap to read the same Firestore document.
  Map<String, dynamic> toScoringConfigMap() {
    // Build score fields from scoreActions + primary unit
    final List<Map<String, dynamic>> fields = [];
    
    // Primary score field
    fields.add({
      'id': primaryScoreUnit.endsWith('s') ? primaryScoreUnit : '${primaryScoreUnit}s',
      'name': primaryScoreUnit[0].toUpperCase() + primaryScoreUnit.substring(1) + (primaryScoreUnit.endsWith('s') ? '' : 's'),
      'type': 'number',
      'isPrimary': true,
      'showInCard': true,
      'minValue': 0,
      'unit': primaryScoreUnit.endsWith('s') ? primaryScoreUnit : '${primaryScoreUnit}s',
      'displayOrder': 0,
    });
    
    // Add secondary fields from score actions (unique categories)
    int order = 1;
    final seenCategories = <String>{};
    for (final action in scoreActions) {
      if (action.category != 'score' && !seenCategories.contains(action.category)) {
        seenCategories.add(action.category);
        fields.add({
          'id': action.category,
          'name': action.category[0].toUpperCase() + action.category.substring(1),
          'type': 'number',
          'isPrimary': false,
          'showInCard': false,
          'minValue': 0,
          'unit': action.category,
          'displayOrder': order++,
        });
      }
    }
    
    String winCond;
    switch (winCondition) {
      case WinCondition.highestScore:
        winCond = 'highest';
        break;
      case WinCondition.mostSetsWon:
        winCond = 'best_of';
        break;
      case WinCondition.mostRoundsWon:
        winCond = 'best_of';
        break;
      case WinCondition.targetReached:
        winCond = 'highest';
        break;
    }
    
    return {
      'scoreType': primaryScoreUnit.endsWith('s') ? primaryScoreUnit : '${primaryScoreUnit}s',
      'scoreFields': fields,
      'winCondition': winCond,
    };
  }

  SportConfigModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    bool? isDefault,
    SportType? sportType,
    StructureType? structureType,
    int? duration,
    int? overs,
    int? periods,
    int? pointsToWin,
    bool? hasBreaks,
    int? breakDuration,
    int? playingPlayers,
    int? minPlayers,
    int? maxPlayers,
    bool? allowSubstitutions,
    String? primaryScoreUnit,
    List<ScoreAction>? scoreActions,
    WinCondition? winCondition,
    bool? supportsTie,
    bool? trackIndividualStats,
    bool? hasFouls,
    bool? hasTimeouts,
    bool? hasExtras,
    Map<String, dynamic>? customRules,
    List<QuickActionButton>? quickActions,
    Color? primaryColor,
    DateTime? createdAt,
  }) {
    return SportConfigModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      sportType: sportType ?? this.sportType,
      structureType: structureType ?? this.structureType,
      duration: duration ?? this.duration,
      overs: overs ?? this.overs,
      periods: periods ?? this.periods,
      pointsToWin: pointsToWin ?? this.pointsToWin,
      hasBreaks: hasBreaks ?? this.hasBreaks,
      breakDuration: breakDuration ?? this.breakDuration,
      playingPlayers: playingPlayers ?? this.playingPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      allowSubstitutions: allowSubstitutions ?? this.allowSubstitutions,
      primaryScoreUnit: primaryScoreUnit ?? this.primaryScoreUnit,
      scoreActions: scoreActions ?? this.scoreActions,
      winCondition: winCondition ?? this.winCondition,
      supportsTie: supportsTie ?? this.supportsTie,
      trackIndividualStats: trackIndividualStats ?? this.trackIndividualStats,
      hasFouls: hasFouls ?? this.hasFouls,
      hasTimeouts: hasTimeouts ?? this.hasTimeouts,
      hasExtras: hasExtras ?? this.hasExtras,
      customRules: customRules ?? this.customRules,
      quickActions: quickActions ?? this.quickActions,
      primaryColor: primaryColor ?? this.primaryColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}