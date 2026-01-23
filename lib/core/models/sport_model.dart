import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SportModel extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String description;
  final DateTime createdAt;

  const SportModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SportModel.fromMap(Map<String, dynamic> map) {
    return SportModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory SportModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SportModel.fromMap(data);
  }

  SportModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    DateTime? createdAt,
  }) {
    return SportModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, description, createdAt];
}
