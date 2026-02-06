import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PlayerModel extends Equatable {
  final String id;
  final String name;
  final String idNumber;
  final String teamId;
  final String sportId;
  final DateTime createdAt;
  final Map<String, dynamic>? additionalInfo;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.idNumber,
    required this.teamId,
    required this.sportId,
    required this.createdAt,
    this.additionalInfo,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map, String id) {
    return PlayerModel(
      id: id,
      name: map['name'] ?? '',
      idNumber: map['idNumber'] ?? '',
      teamId: map['teamId'] ?? '',
      sportId: map['sportId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalInfo: map['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  factory PlayerModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'idNumber': idNumber,
      'teamId': teamId,
      'sportId': sportId,
      'createdAt': Timestamp.fromDate(createdAt),
      'additionalInfo': additionalInfo,
    };
  }

  PlayerModel copyWith({
    String? id,
    String? name,
    String? idNumber,
    String? teamId,
    String? sportId,
    DateTime? createdAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      idNumber: idNumber ?? this.idNumber,
      teamId: teamId ?? this.teamId,
      sportId: sportId ?? this.sportId,
      createdAt: createdAt ?? this.createdAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  List<Object?> get props => [id, name, idNumber, teamId, sportId, createdAt, additionalInfo];
}
