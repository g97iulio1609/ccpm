import 'package:alphanessone/viewer/domain/entities/series.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id; // ID dell'istanza dell'esercizio nel workout specifico
  final String
      originalExerciseId; // ID dell'esercizio nel database generale degli esercizi
  final String name;
  final String? variant;
  final String type; // es. 'weight', 'time', 'reps_only'
  final int order;
  final String? superSetId;
  final List<Series> series;
  final String? note;
  final String workoutId;

  Exercise({
    required this.id,
    required this.originalExerciseId,
    required this.name,
    this.variant,
    required this.type,
    required this.order,
    this.superSetId,
    List<Series>? series,
    this.note,
    required this.workoutId,
  }) : series = series ?? [];

  factory Exercise.empty() {
    return Exercise(
      id: '',
      originalExerciseId: '',
      name: '',
      type: 'weight', // Default type
      order: 0,
      series: [],
      workoutId: '',
    );
  }

  Exercise copyWith({
    String? id,
    String? originalExerciseId,
    String? name,
    String? variant,
    String? type,
    int? order,
    String? superSetId,
    List<Series>? series,
    String? note,
    String? workoutId,
  }) {
    return Exercise(
      id: id ?? this.id,
      originalExerciseId: originalExerciseId ?? this.originalExerciseId,
      name: name ?? this.name,
      variant: variant ?? this.variant,
      type: type ?? this.type,
      order: order ?? this.order,
      superSetId: superSetId ?? this.superSetId,
      series: series ?? this.series,
      note: note ?? this.note,
      workoutId: workoutId ?? this.workoutId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' è l'ID del documento
      'workoutId': workoutId,
      'originalExerciseId': originalExerciseId,
      'name': name,
      'variant': variant,
      'type': type,
      'order': order,
      'superSetId': superSetId,
      // 'series' non viene salvato qui, ma nella sua collezione separata.
      // 'note' non viene salvato qui, ma nella sua collezione separata.
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map, String documentId,
      List<Series> series, String? note) {
    // Le serie e le note vengono passate separatamente perché recuperate da altre collezioni
    return Exercise(
      id: documentId,
      workoutId: map['workoutId'] as String,
      originalExerciseId: map['originalExerciseId'] as String? ??
          map['exerciseId'] as String? ??
          documentId, // Fallback per vecchi dati
      name: map['name'] as String,
      variant: map['variant'] as String?,
      type: map['type'] as String? ??
          'weight', // Default a 'weight' se non specificato
      order: map['order'] as int,
      superSetId: map['superSetId'] as String?,
      series: series, // Lista di Series iniettata
      note: note, // Nota iniettata
    );
  }
}
