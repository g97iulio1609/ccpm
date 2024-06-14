import 'package:cloud_firestore/cloud_firestore.dart';

import 'week_model.dart';

class TrainingProgram {
  String? id;
  String name;
  String description;
  String athleteId;
  int mesocycleNumber;
  bool hide;
  String status;

  List<Week> weeks;
  List<String> trackToDeleteWeeks = [];
  List<String> trackToDeleteWorkouts = [];
  List<String> trackToDeleteExercises = [];
  List<String> trackToDeleteSeries = [];

  TrainingProgram({
    this.id,
    this.name = '',
    this.description = '',
    this.athleteId = '',
    this.mesocycleNumber = 0,
    this.hide = false,
    this.status = 'private',
    List<Week>? weeks,
  }) : weeks = weeks ?? [];

  TrainingProgram copyWith({
    String? id,
    String? name,
    String? description,
    String? athleteId,
    String? status,
    int? mesocycleNumber,
    List<Week>? weeks,
  }) {
    return TrainingProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      athleteId: athleteId ?? this.athleteId,
      status: status ?? this.status,
      mesocycleNumber: mesocycleNumber ?? this.mesocycleNumber,
      weeks: weeks ?? this.weeks.map((week) => week.copyWith()).toList(),
    );
  }

  factory TrainingProgram.fromMap(Map<String, dynamic> map) {
    return TrainingProgram(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      athleteId: map['athleteId'],
      status: map['status'] ?? 'private',
      mesocycleNumber: map['mesocycleNumber'],
      weeks: List<Week>.from(map['weeks']?.map((x) => Week.fromMap(x)) ?? []),
    );
  }

  factory TrainingProgram.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TrainingProgram(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      athleteId: data['athleteId'],
      status: data['status'] ?? 'private',
      mesocycleNumber: data['mesocycleNumber'],
      weeks: (data['weeks'] as List<dynamic>? ?? [])
          .map((week) => Week.fromFirestore(week))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'athleteId': athleteId,
      'status': status,
      'mesocycleNumber': mesocycleNumber,
      'weeks': weeks.map((x) => x.toMap()).toList(),
    };
  }
}
