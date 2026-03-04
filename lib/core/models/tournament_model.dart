import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TournamentFormat { roundRobin, knockout, groupStage }

class TournamentModel extends Equatable {
  final String id;
  final String name;
  final String sportId;
  final String? category; // Boys, Girls, Faculty
  final TournamentFormat format;
  final List<String> teamIds;
  final String status; // draft, ongoing, completed
  final DateTime startDate;
  final DateTime? endDate;
  final String? venue;
  final int? groupCount; // For group-stage format
  final DateTime createdAt;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.sportId,
    this.category,
    required this.format,
    required this.teamIds,
    required this.status,
    required this.startDate,
    this.endDate,
    this.venue,
    this.groupCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sportId': sportId,
      'category': category,
      'format': format.name,
      'teamIds': teamIds,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'venue': venue,
      'groupCount': groupCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TournamentModel.fromMap(Map<String, dynamic> map) {
    return TournamentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sportId: map['sportId'] ?? '',
      category: map['category'],
      format: TournamentFormat.values.firstWhere(
        (f) => f.name == map['format'],
        orElse: () => TournamentFormat.roundRobin,
      ),
      teamIds: List<String>.from(map['teamIds'] ?? []),
      status: map['status'] ?? 'draft',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      venue: map['venue'],
      groupCount: map['groupCount'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory TournamentModel.fromSnapshot(DocumentSnapshot doc) {
    return TournamentModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  TournamentModel copyWith({
    String? id,
    String? name,
    String? sportId,
    String? category,
    TournamentFormat? format,
    List<String>? teamIds,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? venue,
    int? groupCount,
    DateTime? createdAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sportId: sportId ?? this.sportId,
      category: category ?? this.category,
      format: format ?? this.format,
      teamIds: teamIds ?? this.teamIds,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      groupCount: groupCount ?? this.groupCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, sportId, format, teamIds, status, startDate];
}
