import 'package:flutter/material.dart';
import 'sport_config_comprehensive.dart';

class DefaultSportConfigurations {
  static List<SportConfigModel> getAllDefaultSports() {
    return [
      getCricketConfig(),
      getFootballConfig(),
      getFutsalConfig(),
      getKabaddiConfig(),
      getBasketballConfig(),
      getHandballConfig(),
      getVolleyballConfig(),
      getBadmintonConfig(),
      getTableTennisConfig(),
      getTugOfWarConfig(),
      getKhoKhoConfig(),
      getUltimateFrisbeeConfig(),
    ];
  }

  static SportConfigModel getCricketConfig() {
    return SportConfigModel(
      id: 'cricket',
      name: 'Cricket',
      icon: '🏏',
      description: 'Professional Cricket with overs-based gameplay',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.oversBased,
      overs: 20,
      periods: 2, // 2 innings
      hasBreaks: true,
      breakDuration: 15,
      playingPlayers: 11,
      minPlayers: 11,
      maxPlayers: 15,
      allowSubstitutions: false,
      primaryScoreUnit: 'run',
      scoreActions: [
        const ScoreAction(id: '0', name: 'Dot Ball', value: 0, category: 'score', displayOrder: 0),
        const ScoreAction(id: '1', name: '1 Run', value: 1, category: 'score', displayOrder: 1, requiresPlayer: true),
        const ScoreAction(id: '2', name: '2 Runs', value: 2, category: 'score', displayOrder: 2, requiresPlayer: true),
        const ScoreAction(id: '3', name: '3 Runs', value: 3, category: 'score', displayOrder: 3, requiresPlayer: true),
        const ScoreAction(id: '4', name: 'Four', value: 4, category: 'score', displayOrder: 4, requiresPlayer: true, color: Colors.green),
        const ScoreAction(id: '6', name: 'Six', value: 6, category: 'score', displayOrder: 5, requiresPlayer: true, color: Colors.orange),
        const ScoreAction(id: 'wide', name: 'Wide', value: 1, category: 'extra', displayOrder: 6),
        const ScoreAction(id: 'noball', name: 'No Ball', value: 1, category: 'extra', displayOrder: 7),
        const ScoreAction(id: 'wicket', name: 'Wicket', value: 0, category: 'wicket', displayOrder: 8, endsPlay: true, requiresPlayer: true, color: Colors.red),
      ],
      winCondition: WinCondition.highestScore,
      supportsTie: true,
      trackIndividualStats: true,
      hasFouls: false,
      hasTimeouts: false,
      hasExtras: true,
      customRules: {
        'powerplay_overs': 6,
        'free_hit_after_noball': true,
        'duckworth_lewis': true,
      },
      quickActions: [
        const QuickActionButton(actionId: '0', label: '0', position: 0, isPrimary: true),
        const QuickActionButton(actionId: '1', label: '1', position: 1, isPrimary: true),
        const QuickActionButton(actionId: '2', label: '2', position: 2, isPrimary: true),
        const QuickActionButton(actionId: '4', label: '4', position: 3, isPrimary: true),
        const QuickActionButton(actionId: '6', label: '6', position: 4, isPrimary: true),
        const QuickActionButton(actionId: 'wicket', label: 'OUT', position: 5),
      ],
      primaryColor: const Color(0xFF4CAF50),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getFootballConfig() {
    return SportConfigModel(
      id: 'football',
      name: 'Football',
      icon: '⚽',
      description: 'Association Football with 90-minute matches',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.timeBased,
      duration: 90,
      periods: 2,
      hasBreaks: true,
      breakDuration: 15,
      playingPlayers: 11,
      minPlayers: 11,
      maxPlayers: 18,
      allowSubstitutions: true,
      primaryScoreUnit: 'goal',
      scoreActions: [
        const ScoreAction(id: 'goal', name: 'Goal', value: 1, category: 'score', requiresPlayer: true, color: Colors.green, displayOrder: 0),
        const ScoreAction(id: 'own_goal', name: 'Own Goal', value: 1, category: 'score', requiresPlayer: true, displayOrder: 1),
        const ScoreAction(id: 'yellow', name: 'Yellow Card', value: 0, category: 'penalty', requiresPlayer: true, color: Colors.yellow, displayOrder: 2),
        const ScoreAction(id: 'red', name: 'Red Card', value: 0, category: 'penalty', requiresPlayer: true, color: Colors.red, displayOrder: 3),
      ],
      winCondition: WinCondition.highestScore,
      supportsTie: true,
      trackIndividualStats: true,
      hasFouls: true,
      hasTimeouts: false,
      hasExtras: false,
      quickActions: [
        const QuickActionButton(actionId: 'goal', label: 'GOAL', position: 0, isPrimary: true),
        const QuickActionButton(actionId: 'yellow', label: 'Yellow', position: 1),
        const QuickActionButton(actionId: 'red', label: 'Red', position: 2),
      ],
      primaryColor: const Color(0xFF2196F3),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getFutsalConfig() {
    return SportConfigModel(
      id: 'futsal',
      name: 'Futsal',
      icon: '⚽',
      description: '5-a-side Indoor Football',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.timeBased,
      duration: 40,
      periods: 2,
      hasBreaks: true,
      breakDuration: 10,
      playingPlayers: 5,
      minPlayers: 5,
      maxPlayers: 12,
      allowSubstitutions: true,
      primaryScoreUnit: 'goal',
      scoreActions: [
        const ScoreAction(id: 'goal', name: 'Goal', value: 1, category: 'score', requiresPlayer: true, color: Colors.green, displayOrder: 0),
        const ScoreAction(id: 'yellow', name: 'Yellow Card', value: 0, category: 'penalty', requiresPlayer: true, color: Colors.yellow, displayOrder: 1),
        const ScoreAction(id: 'red', name: 'Red Card', value: 0, category: 'penalty', requiresPlayer: true, color: Colors.red, displayOrder: 2),
      ],
      winCondition: WinCondition.highestScore,
      supportsTie: true,
      trackIndividualStats: true,
      hasFouls: true,
      hasTimeouts: true,
      hasExtras: false,
      quickActions: [
        const QuickActionButton(actionId: 'goal', label: 'GOAL', position: 0, isPrimary: true),
      ],
      primaryColor: const Color(0xFF2196F3),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getKabaddiConfig() {
    return SportConfigModel(
      id: 'kabaddi',
      name: 'Kabaddi',
      icon: '🤼',
      description: 'Traditional Indian contact sport',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.timeBased,
      duration: 40,
      periods: 2,
      hasBreaks: true,
      breakDuration: 5,
      playingPlayers: 7,
      minPlayers: 7,
      maxPlayers: 12,
      allowSubstitutions: true,
      primaryScoreUnit: 'point',
      scoreActions: [
        const ScoreAction(id: 'touch_point', name: 'Touch Point', value: 1, category: 'score', requiresPlayer: true, displayOrder: 0),
        const ScoreAction(id: 'bonus_point', name: 'Bonus Point', value: 1, category: 'score', requiresPlayer: true, displayOrder: 1),
        const ScoreAction(id: 'tackle_point', name: 'Tackle Point', value: 1, category: 'score', requiresPlayer: true, displayOrder: 2),
        const ScoreAction(id: 'all_out', name: 'All Out', value: 2, category: 'bonus', displayOrder: 3),
      ],
      winCondition: WinCondition.highestScore,
      supportsTie: true,
      trackIndividualStats: true,
      hasFouls: false,
      hasTimeouts: true,
      hasExtras: false,
      customRules: {
        'raid_time': 30,
        'bonus_line_crosses': 3,
        'all_out_bonus': 2,
      },
      quickActions: [
        const QuickActionButton(actionId: 'touch_point', label: 'Touch', position: 0, isPrimary: true),
        const QuickActionButton(actionId: 'bonus_point', label: 'Bonus', position: 1, isPrimary: true),
        const QuickActionButton(actionId: 'tackle_point', label: 'Tackle', position: 2, isPrimary: true),
        const QuickActionButton(actionId: 'all_out', label: 'All Out', position: 3),
      ],
      primaryColor: const Color(0xFFFF9800),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getBasketballConfig() {
    return SportConfigModel(
      id: 'basketball',
      name: 'Basketball',
      icon: '🏀',
      description: 'Fast-paced indoor basketball',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.timeBased,
      duration: 40,
      periods: 4,
      hasBreaks: true,
      breakDuration: 2,
      playingPlayers: 5,
      minPlayers: 5,
      maxPlayers: 12,
      allowSubstitutions: true,
      primaryScoreUnit: 'point',
      scoreActions: [
        const ScoreAction(id: 'free_throw', name: 'Free Throw', value: 1, category: 'score', requiresPlayer: true, displayOrder: 0),
        const ScoreAction(id: 'two_pointer', name: '2-Pointer', value: 2, category: 'score', requiresPlayer: true, displayOrder: 1),
        const ScoreAction(id: 'three_pointer', name: '3-Pointer', value: 3, category: 'score', requiresPlayer: true, displayOrder: 2),
        const ScoreAction(id: 'foul', name: 'Foul', value: 0, category: 'penalty', requiresPlayer: true, displayOrder: 3),
      ],
      winCondition: WinCondition.highestScore,
      supportsTie: true,
      trackIndividualStats: true,
      hasFouls: true,
      hasTimeouts: true,
      hasExtras: false,
      quickActions: [
        const QuickActionButton(actionId: 'free_throw', label: '1 PT', position: 0, isPrimary: true),
        const QuickActionButton(actionId: 'two_pointer', label: '2 PT', position: 1, isPrimary: true),
        const QuickActionButton(actionId: 'three_pointer', label: '3 PT', position: 2, isPrimary: true),
      ],
      primaryColor: const Color(0xFFFF5722),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getHandballConfig() {
    return SportConfigModel(
      id: 'handball',
      name: 'Handball',
      icon: '🤾',
      description: 'Team handball with goals and penalties',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.timeBased,
      duration: 60,
      periods: 2,
      hasBreaks: true,
      breakDuration: 15,
      playingPlayers: 7,
      minPlayers: 7,
      maxPlayers: 14,
      allowSubstitutions: true,
      primaryScoreUnit: 'goal',
      scoreActions: [
        const ScoreAction(id: 'goal', name: 'Goal', value: 1, category: 'score', requiresPlayer: true, displayOrder: 0),
        const ScoreAction(id: 'penalty_goal', name: 'Penalty Goal', value: 1, category: 'score', requiresPlayer: true, displayOrder: 1),
        const ScoreAction(id: 'yellow_card', name: 'Yellow Card', value: 0, category: 'penalty', requiresPlayer: true, displayOrder: 2),
        const ScoreAction(id: 'two_minute', name: '2-Min Suspension', value: 0, category: 'penalty', requiresPlayer: true, displayOrder: 3),
      ],
      winCondition: WinCondition.highestScore,
      supportsTie: true,
      trackIndividualStats: true,
      hasFouls: true,
      hasTimeouts: true,
      hasExtras: false,
      quickActions: [
        const QuickActionButton(actionId: 'goal', label: 'GOAL', position: 0, isPrimary: true),
        const QuickActionButton(actionId: 'penalty_goal', label: 'Penalty', position: 1),
        const QuickActionButton(actionId: 'two_minute', label: '2 Min', position: 2),
      ],
      primaryColor: const Color(0xFF3F51B5),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getVolleyballConfig() {
    return SportConfigModel(
      id: 'volleyball',
      name: 'Volleyball',
      icon: '🏐',
      description: 'Best-of-5 sets volleyball',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.setsBased,
      periods: 5, // Best of 5 sets
      pointsToWin: 25,
      playingPlayers: 6,
      minPlayers: 6,
      maxPlayers: 12,
      allowSubstitutions: true,
      primaryScoreUnit: 'point',
      scoreActions: [
        const ScoreAction(id: 'point', name: 'Point', value: 1, category: 'score', requiresPlayer: true, displayOrder: 0),
        const ScoreAction(id: 'ace', name: 'Ace', value: 1, category: 'score', requiresPlayer: true, displayOrder: 1),
        const ScoreAction(id: 'block', name: 'Block Point', value: 1, category: 'score', requiresPlayer: true, displayOrder: 2),
        const ScoreAction(id: 'spike', name: 'Spike Point', value: 1, category: 'score', requiresPlayer: true, displayOrder: 3),
      ],
      winCondition: WinCondition.mostSetsWon,
      supportsTie: false,
      trackIndividualStats: true,
      hasFouls: false,
      hasTimeouts: true,
      hasExtras: false,
      customRules: {
        'deuce_points': 25,
        'final_set_points': 15,
        'win_by_points': 2,
      },
      quickActions: [
        const QuickActionButton(actionId: 'point', label: 'Point', position: 0, isPrimary: true),
        const QuickActionButton(actionId: 'ace', label: 'Ace', position: 1),
        const QuickActionButton(actionId: 'block', label: 'Block', position: 2),
      ],
      primaryColor: const Color(0xFF9C27B0),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getBadmintonConfig() {
    return SportConfigModel(
      id: 'badminton',
      name: 'Badminton',
      icon: '🏸',
      description: 'Racket sport - singles or doubles',
      isDefault: true,
      sportType: SportType.individual,
      structureType: StructureType.setsBased,
      periods: 3, // Best of 3 games
      pointsToWin: 21,
      playingPlayers: 1,
      minPlayers: 1,
      maxPlayers: 2,
      allowSubstitutions: false,
      primaryScoreUnit: 'point',
      scoreActions: [
        const ScoreAction(id: 'point', name: 'Point', value: 1, category: 'score', displayOrder: 0),
        const ScoreAction(id: 'smash', name: 'Smash Point', value: 1, category: 'score', displayOrder: 1),
      ],
      winCondition: WinCondition.mostSetsWon,
      supportsTie: false,
      trackIndividualStats: true,
      hasFouls: false,
      hasTimeouts: false,
      hasExtras: false,
      customRules: {
        'deuce_points': 21,
        'win_by_points': 2,
        'max_points': 30,
      },
      quickActions: [
        const QuickActionButton(actionId: 'point', label: 'Point', position: 0, isPrimary: true),
      ],
      primaryColor: const Color(0xFF00BCD4),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getTableTennisConfig() {
    return SportConfigModel(
      id: 'table_tennis',
      name: 'Table Tennis',
      icon: '🏓',
      description: 'Fast-paced table tennis matches',
      isDefault: true,
      sportType: SportType.individual,
      structureType: StructureType.setsBased,
      periods: 5, // Best of 5 games
      pointsToWin: 11,
      playingPlayers: 1,
      minPlayers: 1,
      maxPlayers: 2,
      allowSubstitutions: false,
      primaryScoreUnit: 'point',
      scoreActions: [
        const ScoreAction(id: 'point', name: 'Point', value: 1, category: 'score', displayOrder: 0),
      ],
      winCondition: WinCondition.mostSetsWon,
      supportsTie: false,
      trackIndividualStats: true,
      hasFouls: false,
      hasTimeouts: false,
      hasExtras: false,
      customRules: {
        'deuce_points': 11,
        'win_by_points': 2,
      },
      quickActions: [
        const QuickActionButton(actionId: 'point', label: 'Point', position: 0, isPrimary: true),
      ],
      primaryColor: const Color(0xFFE91E63),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getTugOfWarConfig() {
    return SportConfigModel(
      id: 'tug_of_war',
      name: 'Tug of War',
      icon: '🪢',
      description: 'Strength-based team pulling contest',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.roundsBased,
      periods: 3, // Best of 3 pulls
      playingPlayers: 8,
      minPlayers: 8,
      maxPlayers: 10,
      allowSubstitutions: true,
      primaryScoreUnit: 'round',
      scoreActions: [
        const ScoreAction(id: 'round_won', name: 'Round Won', value: 1, category: 'score', displayOrder: 0),
      ],
      winCondition: WinCondition.mostRoundsWon,
      supportsTie: false,
      trackIndividualStats: false,
      hasFouls: false,
      hasTimeouts: false,
      hasExtras: false,
      customRules: {
        'best_of_rounds': 3,
        'pull_time_limit': 120,
      },
      quickActions: [
        const QuickActionButton(actionId: 'round_won', label: 'Round Won', position: 0, isPrimary: true),
      ],
      primaryColor: const Color(0xFF795548),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getKhoKhoConfig() {
    return SportConfigModel(
      id: 'kho_kho',
      name: 'Kho-Kho',
      icon: '🏃',
      description: 'Traditional Indian chase sport',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.timeBased,
      duration: 36,
      periods: 2,
      hasBreaks: true,
      breakDuration: 5,
      playingPlayers: 9,
      minPlayers: 9,
      maxPlayers: 12,
      allowSubstitutions: false,
      primaryScoreUnit: 'point',
      scoreActions: [
        const ScoreAction(id: 'touch', name: 'Touch', value: 1, category: 'score', displayOrder: 0),
        const ScoreAction(id: 'time_bonus', name: 'Time Bonus', value: 1, category: 'bonus', displayOrder: 1),
      ],
      winCondition: WinCondition.highestScore,
      supportsTie: true,
      trackIndividualStats: true,
      hasFouls: false,
      hasTimeouts: false,
      hasExtras: false,
      customRules: {
        'chase_time': 540, // 9 minutes in seconds
        'innings_per_team': 2,
      },
      quickActions: [
        const QuickActionButton(actionId: 'touch', label: 'Touch', position: 0, isPrimary: true),
        const QuickActionButton(actionId: 'time_bonus', label: 'Bonus', position: 1),
      ],
      primaryColor: const Color(0xFF607D8B),
      createdAt: DateTime.now(),
    );
  }

  static SportConfigModel getUltimateFrisbeeConfig() {
    return SportConfigModel(
      id: 'ultimate_frisbee',
      name: 'Ultimate Frisbee',
      icon: '🥏',
      description: 'Non-contact disc sport',
      isDefault: true,
      sportType: SportType.team,
      structureType: StructureType.pointsBased,
      pointsToWin: 15,
      playingPlayers: 7,
      minPlayers: 7,
      maxPlayers: 14,
      allowSubstitutions: true,
      primaryScoreUnit: 'point',
      scoreActions: [
        const ScoreAction(id: 'goal', name: 'Goal', value: 1, category: 'score', requiresPlayer: true, displayOrder: 0),
        const ScoreAction(id: 'assist', name: 'Assist', value: 0, category: 'stat', requiresPlayer: true, displayOrder: 1),
        const ScoreAction(id: 'block', name: 'Block', value: 0, category: 'stat', requiresPlayer: true, displayOrder: 2),
        const ScoreAction(id: 'drop', name: 'Drop', value: 0, category: 'turnover', displayOrder: 3),
        const ScoreAction(id: 'throwaway', name: 'Throwaway', value: 0, category: 'turnover', displayOrder: 4),
      ],
      winCondition: WinCondition.targetReached,
      supportsTie: false,
      trackIndividualStats: true,
      hasFouls: false,
      hasTimeouts: true,
      hasExtras: false,
      customRules: {
        'win_by_points': 2,
        'halftime_at': 8,
        'soft_time_cap': 75,
        'hard_time_cap': 90,
      },
      quickActions: [
        const QuickActionButton(actionId: 'goal', label: 'GOAL', position: 0, isPrimary: true),
        const QuickActionButton(actionId: 'assist', label: 'Assist', position: 1),
        const QuickActionButton(actionId: 'block', label: 'Block', position: 2),
      ],
      primaryColor: const Color(0xFF009688),
      createdAt: DateTime.now(),
    );
  }
}