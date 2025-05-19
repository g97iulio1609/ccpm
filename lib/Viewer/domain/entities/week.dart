import 'package:alphanessone/viewer/domain/entities/workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Week {
  final String id;
  final String programId;
  final String name; // Es. "Settimana 1", "Blocco Forza"
  final String? description;
  final int number; // Numero progressivo della settimana
  final List<Workout> workouts;
  final bool isCompleted;

  Week({
    required this.id,
    required this.programId,
    required this.name,
    this.description,
    required this.number,
    List<Workout>? workouts, // Modificato per default a lista vuota
    this.isCompleted = false,
  }) : workouts = workouts ?? []; // Assicura che workouts sia sempre una lista

  factory Week.empty() {
    return Week(
      id: '',
      programId: '',
      name: '',
      number: 0,
      workouts: [],
      isCompleted: false,
    );
  }

  Week copyWith({
    String? id,
    String? programId,
    String? name,
    String? description,
    int? number,
    List<Workout>? workouts,
    bool? isCompleted,
  }) {
    return Week(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      description: description ?? this.description,
      number: number ?? this.number,
      workouts: workouts ?? this.workouts,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' è l'ID del documento
      'programId': programId,
      'name': name,
      'description': description,
      'number': number,
      'isCompleted': isCompleted,
      // 'workouts' non vengono salvati qui, ma nella loro collezione separata.
    };
  }

  factory Week.fromMap(
      Map<String, dynamic> map, String documentId, List<Workout> workouts) {
    // I workouts vengono passati separatamente perché recuperati da altre collezioni
    return Week(
      id: documentId,
      programId: map['programId'] as String,
      name: map['name'] as String? ??
          'Settimana ${map['number'] ?? 'N/A'}', // Fallback nome
      description: map['description'] as String?,
      number: map['number'] as int,
      workouts: workouts, // Lista di Workout iniettata
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
