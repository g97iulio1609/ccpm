import 'package:alphanessone/viewer/domain/entities/exercise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String weekId;
  final String name; // Es. "Giorno A", "Push", "Allenamento 1"
  final String? description;
  final int order; // Ordine del workout all'interno della settimana
  final List<Exercise> exercises;
  final DateTime? lastPerformed;
  final bool isCompleted;

  Workout({
    required this.id,
    required this.weekId,
    required this.name,
    this.description,
    required this.order,
    List<Exercise>? exercises, // Modificato per default a lista vuota
    this.lastPerformed,
    this.isCompleted = false,
  }) : exercises =
            exercises ?? []; // Assicura che exercises sia sempre una lista

  factory Workout.empty() {
    return Workout(
      id: '',
      weekId: '',
      name: '',
      order: 0,
      exercises: [],
      isCompleted: false,
    );
  }

  Workout copyWith({
    String? id,
    String? weekId,
    String? name,
    String? description,
    int? order,
    List<Exercise>? exercises,
    DateTime? lastPerformed,
    bool? isCompleted,
  }) {
    return Workout(
      id: id ?? this.id,
      weekId: weekId ?? this.weekId,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      exercises: exercises ?? this.exercises,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' è l'ID del documento
      'weekId': weekId,
      'name': name,
      'description': description,
      'order': order,
      'lastPerformed':
          lastPerformed != null ? Timestamp.fromDate(lastPerformed!) : null,
      'isCompleted': isCompleted,
      // 'exercises' non vengono salvati qui, ma nella loro collezione separata.
    };
  }

  factory Workout.fromMap(
      Map<String, dynamic> map, String documentId, List<Exercise> exercises) {
    // Gli esercizi vengono passati separatamente perché recuperati da altre collezioni
    return Workout(
      id: documentId,
      weekId: map['weekId'] as String,
      name: map['name'] as String? ??
          'Allenamento ${map['order'] ?? 'N/A'}', // Fallback nome
      description: map['description'] as String?,
      order: map['order'] as int,
      exercises: exercises, // Lista di Exercise iniettata
      lastPerformed: (map['lastPerformed'] as Timestamp?)?.toDate(),
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
