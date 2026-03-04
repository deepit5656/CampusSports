import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class InstituteModel extends Equatable {
  final String id;
  final String name;
  final String shortName; // e.g., "CS", "EE", "ME"
  final String? logo;
  final String? color; // hex color for UI
  final int teamCount;
  final DateTime createdAt;

  const InstituteModel({
    required this.id,
    required this.name,
    required this.shortName,
    this.logo,
    this.color,
    this.teamCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'logo': logo,
      'color': color,
      'teamCount': teamCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory InstituteModel.fromMap(Map<String, dynamic> map) {
    return InstituteModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      shortName: map['shortName'] ?? '',
      logo: map['logo'],
      color: map['color'],
      teamCount: map['teamCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory InstituteModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return InstituteModel.fromMap(data);
  }

  InstituteModel copyWith({
    String? id,
    String? name,
    String? shortName,
    String? logo,
    String? color,
    int? teamCount,
    DateTime? createdAt,
  }) {
    return InstituteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logo: logo ?? this.logo,
      color: color ?? this.color,
      teamCount: teamCount ?? this.teamCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, shortName, logo, color, teamCount, createdAt];
}
