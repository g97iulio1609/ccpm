// ignore: file_names
//trainingModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingProgram {
  String? id;
  String name;
  String description;
  String athleteId;
  int mesocycleNumber;
  bool hide;
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
    this.hide=false,
    List<Week>? weeks,
  }) : weeks = weeks ?? [];

  TrainingProgram copyWith({
    String? id,
    String? name,
    String? description,
    String? athleteId,
    int? mesocycleNumber,
    List<Week>? weeks,
  }) {
    return TrainingProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      athleteId: athleteId ?? this.athleteId,
      mesocycleNumber: mesocycleNumber ?? this.mesocycleNumber,
      weeks: weeks ?? this.weeks,
    );
  }

  factory TrainingProgram.fromMap(Map<String, dynamic> map) {
    return TrainingProgram(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      athleteId: map['athleteId'],
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
      'mesocycleNumber': mesocycleNumber,
      'weeks': weeks.map((x) => x.toMap()).toList(),
    };
  }
}

class Week {
  String? id;
  int number;
  List<Workout> workouts;

  Week({
    this.id,
    required this.number,
    List<Workout>? workouts,
  }) : workouts = workouts ?? [];

  factory Week.fromMap(Map<String, dynamic> map) {
    return Week(
      id: map['id'],
      number: map['number'],
      workouts: List<Workout>.from(
          map['workouts']?.map((x) => Workout.fromMap(x)) ?? []),
    );
  }

  factory Week.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Week(
      id: doc.id,
      number: data['number'],
      workouts: (data['workouts'] as List<dynamic>? ?? [])
          .map((doc) => Workout.fromFirestore(doc))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'workouts': workouts.map((x) => x.toMap()).toList(),
    };
  }
}

class Workout {
  String? id;
  int order;
  List<Exercise> exercises;

  Workout({
    this.id,
    required this.order,
    List<Exercise>? exercises,
  }) : exercises = exercises ?? [];

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      order: map['order'],
      exercises: List<Exercise>.from(
          map['exercises']?.map((x) => Exercise.fromMap(x)) ?? []),
    );
  }

  factory Workout.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      order: data['order'],
      exercises: (data['exercises'] as List<dynamic>? ?? [])
          .map((doc) => Exercise.fromFirestore(doc))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      'exercises': exercises.map((x) => x.toMap()).toList(),
    };
  }
}

class Exercise {
  String? id;
  String name;
  String? type; // Aggiungi questa riga
  String variant;
  int order;
  String? exerciseId; // Rendi exerciseId nullable
  List<Series> series;
  List<WeekProgression> weekProgressions;

  Exercise({
    this.id,
    required this.name,
    this.type, 
    required this.variant,
    required this.order,
    this.exerciseId, // Rendi exerciseId nullable
    List<Series>? series,
    List<WeekProgression>? weekProgressions,
  })  : series = series ?? [],
        weekProgressions = weekProgressions ?? [];

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'],
      type: map['type'], // Aggiungi questa riga
      id: map['id'],
      exerciseId: map['exerciseId'],
      variant: map['variant'],
      order: map['order'],
      series:
          List<Series>.from(map['series']?.map((x) => Series.fromMap(x)) ?? []),
      weekProgressions: List<WeekProgression>.from(
          map['weekProgressions']?.map((x) => WeekProgression.fromMap(x)) ??
              []),
    );
  }

  Exercise copyWith({
    String? id,
    String? exerciseId, // Modifica questa riga
    String? name,
    String? type,
    String? variant,
    int? order,
    List<Series>? series,
    List<WeekProgression>? weekProgressions,
  }) {
    return Exercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId, // Modifica questa riga
      name: name ?? this.name,
      type: type ?? this.type,
      variant: variant ?? this.variant,
      order: order ?? this.order,
      series: series ?? this.series,
      weekProgressions: weekProgressions ?? this.weekProgressions,
    );
  }

factory Exercise.fromFirestore(DocumentSnapshot doc) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  return Exercise(
    id: doc.id,
    exerciseId: data['exerciseId'] ?? '',
    name: data['name'] ?? '',
    type: data['type'] ?? '',
    variant: data['variant'] ?? '',
    order: data['order']?.toInt() ?? 0,
    series: (data['series'] as List<dynamic>? ?? [])
        .map((doc) => Series.fromFirestore(doc))
        .toList(),
    weekProgressions: (data['weekProgressions'] as List<dynamic>? ?? [])
        .map((doc) => WeekProgression.fromMap(doc))
        .toList(),
  );
}

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'name': name,
      'type': type, // Aggiungi questa riga
      'variant': variant,
      'order': order,
      'series': series.map((x) => x.toMap()).toList(),
      'weekProgressions': weekProgressions.map((x) => x.toMap()).toList(),
    };
  }
}

class WeekProgression {
  int weekNumber;
  int reps;
  int sets;
  String intensity;
  String rpe;
  double weight;

  WeekProgression({
    required this.weekNumber,
    required this.reps,
    required this.sets,
    required this.intensity,
    required this.rpe,
    required this.weight,
  });

  factory WeekProgression.fromMap(Map<String, dynamic> map) {
    return WeekProgression(
      weekNumber: map['weekNumber'],
      reps: map['reps'],
      sets: map['sets'],
      intensity: map['intensity'],
      rpe: map['rpe'],
      weight: map['weight'].toDouble(),
    );
  }

  WeekProgression copyWith({
    int? weekNumber,
    int? reps,
    int? sets,
    String? intensity,
    String? rpe,
    double? weight,
  }) {
    return WeekProgression(
      weekNumber: weekNumber ?? this.weekNumber,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      intensity: intensity ?? this.intensity,
      rpe: rpe ?? this.rpe,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
    };
  }
}

class Series {
  String? id;
  String serieId;
  int reps;
  int sets;
  String intensity;
  String rpe;
  double weight;
  int order;
  bool done;
  int reps_done;
  double weight_done;

  Series({
    this.id,
    required this.serieId,
    required this.reps,
    required this.sets,
    required this.intensity,
    required this.rpe,
    required this.weight,
    required this.order,
    this.done = false,
    this.reps_done = 0,
    this.weight_done = 0.0,
  });

factory Series.fromMap(Map<String, dynamic> map) {
  return Series(
    id: map['id'],
    serieId: map['serieId'] ?? '',
    reps: map['reps']?.toInt() ?? 0,
    sets: map['sets']?.toInt() ?? 0,
    intensity: map['intensity'] ?? '',
    rpe: map['rpe'] ?? '',
    weight: map['weight']?.toDouble() ?? 0.0,
    order: map['order']?.toInt() ?? 0,
    done: map['done'] ?? false,
    reps_done: map['reps_done']?.toInt() ?? 0,
    weight_done: map['weight_done']?.toDouble() ?? 0.0,
  );
}


Series copyWith({
  String? serieId,
  int? reps,
  int? sets,
  String? intensity,
  String? rpe,
  double? weight,
  int? order,
  bool? done,
  int? reps_done,
  double? weight_done,
}) {
  return Series(
    serieId: serieId ?? this.serieId,
    reps: reps ?? this.reps,
    sets: sets ?? this.sets,
    intensity: intensity ?? this.intensity,
    rpe: rpe ?? this.rpe,
    weight: weight ?? this.weight,
    order: order ?? this.order,
    done: done ?? this.done,
    reps_done: reps_done ?? this.reps_done,
    weight_done: weight_done ?? this.weight_done,
  );
}


factory Series.fromFirestore(DocumentSnapshot doc) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  return Series(
    id: doc.id,
    serieId: data['serieId'] ?? '',
    reps: data['reps']?.toInt() ?? 0,
    sets: data['sets']?.toInt() ?? 0,
    intensity: data['intensity'] ?? '',
    rpe: data['rpe'] ?? '',
    weight: data['weight']?.toDouble() ?? 0.0,
    order: data['order']?.toInt() ?? 0,
    done: data['done'] ?? false,
    reps_done: data['reps_done']?.toInt() ?? 0,
    weight_done: data['weight_done']?.toDouble() ?? 0.0,
  );
}

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serieId': serieId,
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
      'order': order,
      'done': done,
      'reps_done': reps_done,
      'weight_done': weight_done,
    };
  }
}
