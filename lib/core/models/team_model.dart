import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TeamModel extends Equatable {
  final String id;
  final String name;
  final String department;
  final String logo;
  final String? sportId; // Sport this team belongs to
  final String? instituteId; // Institute this team belongs to
  final int? numberOfPlayers; // Number of players in this team for the sport
  final DateTime createdAt;
  final Map<String, dynamic>? additionalInfo; // Any additional team information

  const TeamModel({
    required this.id,
    required this.name,
    required this.department,
    required this.logo,
    this.sportId,
    this.instituteId,
    this.numberOfPlayers,
    required this.createdAt,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'logo': logo,
      'sportId': sportId,
      'instituteId': instituteId,
      'numberOfPlayers': numberOfPlayers,
      'createdAt': Timestamp.fromDate(createdAt),
      'additionalInfo': additionalInfo,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      logo: map['logo'] ?? '',
      sportId: map['sportId'],
      instituteId: map['instituteId'],
      numberOfPlayers: map['numberOfPlayers'] as int?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      additionalInfo: map['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  factory TeamModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return TeamModel.fromMap(data);
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? department,
    String? logo,
    String? sportId,
    String? instituteId,
    int? numberOfPlayers,
    DateTime? createdAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      logo: logo ?? this.logo,
      sportId: sportId ?? this.sportId,
      instituteId: instituteId ?? this.instituteId,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      createdAt: createdAt ?? this.createdAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  List<Object?> get props => [id, name, department, logo, sportId, instituteId, numberOfPlayers, createdAt, additionalInfo];
}
