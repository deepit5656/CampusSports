import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TeamModel extends Equatable {
  final String id;
  final String name;
  final String department;
  final String logo;
  final List<String> players;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.department,
    required this.logo,
    required this.players,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'logo': logo,
      'players': players,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      logo: map['logo'] ?? '',
      players: List<String>.from(map['players'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory TeamModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel.fromMap(data);
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? department,
    String? logo,
    List<String>? players,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      logo: logo ?? this.logo,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, department, logo, players, createdAt];
}
