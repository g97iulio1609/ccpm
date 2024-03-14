// ignore: file_names
//trainingModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingProgram {
  String? id;
  String name;
  String description;
  String athleteId;
  int mesocycleNumber;
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
      weeks: (data['weeks'] as List<dynamic>? ?? []).map((week) => Week.fromFirestore(week)).toList(),
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
      workouts: List<Workout>.from(map['workouts']?.map((x) => Workout.fromMap(x)) ?? []),
    );
  }

  factory Week.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Week(
      id: doc.id,
      number: data['number'],
      workouts: (data['workouts'] as List<dynamic>? ?? []).map((doc) => Workout.fromFirestore(doc)).toList(),
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
exercises: List<Exercise>.from(map['exercises']?.map((x) => Exercise.fromMap(x)) ?? []),
);
}

factory Workout.fromFirestore(DocumentSnapshot doc) {
Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
return Workout(
id: doc.id,
order: data['order'],
exercises: (data['exercises'] as List<dynamic>? ?? []).map((doc) => Exercise.fromFirestore(doc)).toList(),
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
String variant;
int order;
String? exerciseId;
List<Series> series;

Exercise({
this.id,
this.exerciseId,
required this.name,
required this.variant,
required this.order,
List<Series>? series,
}) : series = series ?? [];

factory Exercise.fromMap(Map<String, dynamic> map) {
return Exercise(
name: map['name'],
id: map['id'],
exerciseId: map['exerciseId'],
variant: map['variant'],
order: map['order'],
series: List<Series>.from(map['series']?.map((x) => Series.fromMap(x)) ?? []),
);
}

factory Exercise.fromFirestore(DocumentSnapshot doc) {
Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
return Exercise(
id: doc.id,
exerciseId: data['exerciseId'],
name: data['name'],
variant: data['variant'],
order: data['order'],
series: (data['series'] as List<dynamic>? ?? []).map((doc) => Series.fromFirestore(doc)).toList(),
);
}

Map<String, dynamic> toMap() {
return {
'id': id,
'exerciseId': id,
'name': name,
'variant': variant,
'order': order,
'series': series.map((x) => x.toMap()).toList(),
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

Series({
this.id,
required this.serieId,
required this.reps,
required this.sets,
required this.intensity,
required this.rpe,
required this.weight,
required this.order,
});

factory Series.fromMap(Map<String, dynamic> map) {
return Series(
id: map['id'],
serieId: map['serieId'] ?? '',
reps: map['reps'],
sets: map['sets'],
intensity: map['intensity'],
rpe: map['rpe'],
weight: map['weight'].toDouble(),
order: map['order'],
);
}

factory Series.fromFirestore(DocumentSnapshot doc) {
Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
return Series(
id: doc.id,
serieId: data['serieId'] ?? '',
reps: data['reps'],
sets: data['sets'],
intensity: data['intensity'],
rpe: data['rpe'],
weight: data.containsKey('weight') ? (data['weight'] ?? 0).toDouble() : 0.0,
order: data['order'],
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
};
}
}