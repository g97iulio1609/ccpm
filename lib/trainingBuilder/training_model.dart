import 'package:cloud_firestore/cloud_firestore.dart';

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

class Week {
  String? id;
  int number;
  List<Workout> workouts;

  Week({
    this.id,
    required this.number,
    List<Workout>? workouts,
  }) : workouts = workouts ?? [];

  Week copyWith({
    String? id,
    int? number,
    List<Workout>? workouts,
  }) {
    return Week(
      id: id ?? this.id,
      number: number ?? this.number,
      workouts: workouts ?? this.workouts.map((workout) => workout.copyWith()).toList(),
    );
  }

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
  List<SuperSet> superSets;

  Workout({
    this.id,
    required this.order,
    List<Exercise>? exercises,
    this.superSets = const [],
  }) : exercises = exercises ?? [];

  Workout copyWith({
    String? id,
    int? order,
    List<Exercise>? exercises,
    List<SuperSet>? superSets,
  }) {
    return Workout(
      id: id ?? this.id,
      order: order ?? this.order,
      exercises: exercises ?? this.exercises.map((exercise) => exercise.copyWith()).toList(),
      superSets: superSets ?? this.superSets.map((superSet) => SuperSet.fromMap(superSet.toMap())).toList(),
    );
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      order: map['order'],
      exercises: List<Exercise>.from(
          map['exercises']?.map((x) => Exercise.fromMap(x)) ?? []),
      superSets: List<SuperSet>.from(
        (map['superSets'] ?? []).map((x) => SuperSet.fromMap(x)),
      ),
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
      superSets: (data['superSets'] as List<dynamic>? ?? [])
          .map((doc) => SuperSet.fromMap(doc))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      'exercises': exercises.map((x) => x.toMap()).toList(),
      'superSets': superSets.map((x) => x.toMap()).toList(),
    };
  }
}

class SuperSet {
  String id;
  String? name;
  List<String> exerciseIds;

  SuperSet({
    required this.id,
    this.name,
    required this.exerciseIds,
  });

  factory SuperSet.fromMap(Map<String, dynamic> map) {
    return SuperSet(
      id: map['id'],
      name: map['name'],
      exerciseIds: List<String>.from(map['exerciseIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exerciseIds': exerciseIds,
    };
  }
}

class Exercise {
  String? id;
  String name;
  String type;
  String variant;
  int order;
  String? exerciseId;
  String? superSetId;
  List<Series> series;
  List<List<WeekProgression>> weekProgressions;

  Exercise({
    this.id,
    required this.name,
    required this.type,
    required this.variant,
    required this.order,
    this.exerciseId,
    this.superSetId,
    List<Series>? series,
    List<List<WeekProgression>>? weekProgressions,
  })  : series = series ?? [],
        weekProgressions = weekProgressions ?? [];

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      id: map['id'],
      exerciseId: map['exerciseId'],
      superSetId: map['superSetId'],
      variant: map['variant'] ?? '',
      order: map['order'] ?? 0,
      series: List<Series>.from(map['series']?.map((x) => Series.fromMap(x)) ?? []),
      weekProgressions: List<List<WeekProgression>>.from(map['weekProgressions']?.map((x) => List<WeekProgression>.from(x.map((y) => WeekProgression.fromMap(y)))) ?? []),
    );
  }

  Exercise copyWith({
    String? id,
    String? exerciseId,
    String? superSetId,
    String? name,
    String? type,
    String? variant,
    int? order,
    List<Series>? series,
    List<List<WeekProgression>>? weekProgressions,
  }) {
    return Exercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      superSetId: superSetId ?? this.superSetId,
      name: name ?? this.name,
      type: type ?? this.type,
      variant: variant ?? this.variant,
      order: order ?? this.order,
      series: series ?? this.series.map((series) => series.copyWith()).toList(),
      weekProgressions: weekProgressions ?? this.weekProgressions.map((weekProgression) => weekProgression.map((progression) => progression.copyWith()).toList()).toList(),
    );
  }

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      exerciseId: data['exerciseId'] ?? '',
      superSetId: data['superSetId'],
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      variant: data['variant'] ?? '',
      order: data['order']?.toInt() ?? 0,
      series: (data['series'] as List<dynamic>? ?? []).map((doc) => Series.fromFirestore(doc)).toList(),
      weekProgressions: (data['weekProgressions'] as List<dynamic>? ?? []).map((weekProgression) => (weekProgression as List<dynamic>).map((progression) => WeekProgression.fromMap(progression)).toList()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'superSetId': superSetId,
      'name': name,
      'type': type,
      'variant': variant,
      'order': order,
      'series': series.map((x) => x.toMap()).toList(),
      'weekProgressions': weekProgressions.map((x) => x.map((y) => y.toMap()).toList()).toList(),
    };
  }
}

class WeekProgression {
  int weekNumber;
  int sessionNumber;
  List<Series> series;

  WeekProgression({
    required this.weekNumber,
    required this.sessionNumber,
    required this.series,
    
  });

  factory WeekProgression.fromMap(Map<String, dynamic> map) {
    return WeekProgression(
      weekNumber: map['weekNumber'],
      sessionNumber: map['sessionNumber'],
      series: List<Series>.from(map['series']?.map((x) => Series.fromMap(x)) ?? []),
    );
  }

  WeekProgression copyWith({
    int? weekNumber,
    int? sessionNumber,
    List<Series>? series,
  }) {
    return WeekProgression(
      weekNumber: weekNumber ?? this.weekNumber,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      series: series ?? this.series.map((series) => series.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'sessionNumber': sessionNumber,
      'series': series.map((x) => x.toMap()).toList(),
    };
  }
}

class Series {
  String? id;
  String? serieId;
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
      reps: int.tryParse(map['reps']?.toString() ?? '0') ?? 0,
      sets: int.tryParse(map['sets']?.toString() ?? '0') ?? 0,
      intensity: map['intensity'] ?? '',
      rpe: map['rpe'] ?? '',
      weight: map['weight']?.toDouble() ?? 0.0,
      order: int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      done: map['done'] ?? false,
      reps_done: int.tryParse(map['reps_done']?.toString() ?? '0') ?? 0,
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
      reps: int.tryParse(data['reps']?.toString() ?? '0') ?? 0,
      sets: int.tryParse(data['sets']?.toString() ?? '0') ?? 0,
      intensity: data['intensity'] ?? '',
      rpe: data['rpe'] ?? '',
      weight: data['weight']?.toDouble() ?? 0.0,
      order: int.tryParse(data['order']?.toString() ?? '0') ?? 0,
      done: data['done'] ?? false,
      reps_done: int.tryParse(data['reps_done']?.toString() ?? '0') ?? 0,
      weight_done: data['weight_done']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,'serieId': serieId,
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

  Map<String, dynamic> toFirestore() {
    return {
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
      'id': id,
      'serieId': serieId,
      'order': order,
      'done': done,
      'reps_done': reps_done,
      'weight_done': weight_done,
    };
  }
}