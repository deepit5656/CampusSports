import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayerRole { batsman, bowler, allRounder, wicketKeeper }

class CricketPlayer {
  final String id;
  final String name;
  final String teamId;
  final PlayerRole role;
  final int jerseyNumber;
  final bool isCaptain;
  final bool isWicketKeeper;
  final DateTime createdAt;

  CricketPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    required this.role,
    this.jerseyNumber = 0,
    this.isCaptain = false,
    this.isWicketKeeper = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teamId': teamId,
      'role': role.name,
      'jerseyNumber': jerseyNumber,
      'isCaptain': isCaptain,
      'isWicketKeeper': isWicketKeeper,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CricketPlayer.fromMap(Map<String, dynamic> map) {
    return CricketPlayer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      teamId: map['teamId'] ?? '',
      role: PlayerRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => PlayerRole.batsman,
      ),
      jerseyNumber: map['jerseyNumber'] ?? 0,
      isCaptain: map['isCaptain'] ?? false,
      isWicketKeeper: map['isWicketKeeper'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  CricketPlayer copyWith({
    String? id,
    String? name,
    String? teamId,
    PlayerRole? role,
    int? jerseyNumber,
    bool? isCaptain,
    bool? isWicketKeeper,
    DateTime? createdAt,
  }) {
    return CricketPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      isCaptain: isCaptain ?? this.isCaptain,
      isWicketKeeper: isWicketKeeper ?? this.isWicketKeeper,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
