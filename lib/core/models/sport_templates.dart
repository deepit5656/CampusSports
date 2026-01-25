import 'package:sports_event_app/core/models/scoring_config_model.dart';

class SportTemplate {
  static ScoringConfig getCricketTemplate() {
    return ScoringConfig(
      scoreType: 'runs',
      winCondition: 'highest',
      scoreFields: [
        ScoreField(
          id: 'runs',
          name: 'Runs',
          type: 'number',
          isPrimary: true,
          showInCard: true,
          minValue: 0,
          unit: 'runs',
          displayOrder: 1,
        ),
        ScoreField(
          id: 'wickets',
          name: 'Wickets',
          type: 'number',
          isPrimary: false,
          showInCard: true,
          minValue: 0,
          maxValue: 11,
          unit: 'wickets',
          displayOrder: 2,
        ),
        ScoreField(
          id: 'overs',
          name: 'Overs',
          type: 'number',
          isPrimary: false,
          showInCard: true,
          minValue: 0,
          maxValue: 50,
          unit: 'overs',
          displayOrder: 3,
        ),
        ScoreField(
          id: 'fours',
          name: 'Fours',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'fours',
          displayOrder: 4,
        ),
        ScoreField(
          id: 'sixes',
          name: 'Sixes',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'sixes',
          displayOrder: 5,
        ),
        ScoreField(
          id: 'extras',
          name: 'Extras',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'extras',
          displayOrder: 6,
        ),
      ],
    );
  }

  static ScoringConfig getFootballTemplate() {
    return ScoringConfig(
      scoreType: 'goals',
      winCondition: 'highest',
      scoreFields: [
        ScoreField(
          id: 'goals',
          name: 'Goals',
          type: 'number',
          isPrimary: true,
          showInCard: true,
          minValue: 0,
          unit: 'goals',
          displayOrder: 1,
        ),
        ScoreField(
          id: 'yellowCards',
          name: 'Yellow Cards',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'yellow cards',
          displayOrder: 2,
        ),
        ScoreField(
          id: 'redCards',
          name: 'Red Cards',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'red cards',
          displayOrder: 3,
        ),
        ScoreField(
          id: 'possession',
          name: 'Possession %',
          type: 'percentage',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          maxValue: 100,
          unit: '%',
          displayOrder: 4,
        ),
      ],
    );
  }

  static ScoringConfig getBasketballTemplate() {
    return ScoringConfig(
      scoreType: 'points',
      winCondition: 'highest',
      scoreFields: [
        ScoreField(
          id: 'points',
          name: 'Points',
          type: 'number',
          isPrimary: true,
          showInCard: true,
          minValue: 0,
          unit: 'points',
          displayOrder: 1,
        ),
        ScoreField(
          id: 'fouls',
          name: 'Fouls',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'fouls',
          displayOrder: 2,
        ),
        ScoreField(
          id: 'threePointers',
          name: 'Three Pointers',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: '3-pointers',
          displayOrder: 3,
        ),
        ScoreField(
          id: 'freeThrows',
          name: 'Free Throws',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'free throws',
          displayOrder: 4,
        ),
      ],
    );
  }

  static ScoringConfig getVolleyballTemplate() {
    return ScoringConfig(
      scoreType: 'sets',
      winCondition: 'best_of',
      scoreFields: [
        ScoreField(
          id: 'setsWon',
          name: 'Sets Won',
          type: 'number',
          isPrimary: true,
          showInCard: true,
          minValue: 0,
          maxValue: 5,
          unit: 'sets',
          displayOrder: 1,
        ),
        ScoreField(
          id: 'totalPoints',
          name: 'Total Points',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'points',
          displayOrder: 2,
        ),
      ],
      additionalConfig: {
        'bestOf': 5,
        'setScores': [], // Will store individual set scores
      },
    );
  }

  static ScoringConfig getBadmintonTemplate() {
    return ScoringConfig(
      scoreType: 'games',
      winCondition: 'best_of',
      scoreFields: [
        ScoreField(
          id: 'gamesWon',
          name: 'Games Won',
          type: 'number',
          isPrimary: true,
          showInCard: true,
          minValue: 0,
          maxValue: 3,
          unit: 'games',
          displayOrder: 1,
        ),
        ScoreField(
          id: 'totalPoints',
          name: 'Total Points',
          type: 'number',
          isPrimary: false,
          showInCard: false,
          minValue: 0,
          unit: 'points',
          displayOrder: 2,
        ),
      ],
      additionalConfig: {
        'bestOf': 3,
        'gameScores': [], // Will store individual game scores
      },
    );
  }

  static ScoringConfig getDefaultTemplate() {
    return ScoringConfig(
      scoreType: 'points',
      winCondition: 'highest',
      scoreFields: [
        ScoreField(
          id: 'score',
          name: 'Score',
          type: 'number',
          isPrimary: true,
          showInCard: true,
          minValue: 0,
          unit: 'points',
          displayOrder: 1,
        ),
      ],
    );
  }

  static Map<String, ScoringConfig> getAllTemplates() {
    return {
      'Cricket': getCricketTemplate(),
      'Football': getFootballTemplate(),
      'Basketball': getBasketballTemplate(),
      'Volleyball': getVolleyballTemplate(),
      'Badminton': getBadmintonTemplate(),
      'Default': getDefaultTemplate(),
    };
  }

  static List<String> getTemplateNames() {
    return ['Cricket', 'Football', 'Basketball', 'Volleyball', 'Badminton', 'Custom'];
  }
}