// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingProgram {
  String? id;
  String name;
  String description;
  String athleteId;
  int mesocycleNumber;
  List<Week> weeks;

  TrainingProgram({
    this.id,
    required this.name,
    required this.description,
    required this.athleteId,
    required this.mesocycleNumber,
    required this.weeks,
  });

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

  Week({this.id, required this.number, required this.workouts});

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

  Workout({this.id, required this.order, required this.exercises});

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
  List<Series> series;

  Exercise({this.id, required this.name, required this.variant, required this.order, required this.series});

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name:map['name'],
      id: map['id'],
      variant: map['variant'],
      order: map['order'],
      series: List<Series>.from(map['series']?.map((x) => Series.fromMap(x)) ?? []),
    );
  }

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name:data['name'],
      variant: data['variant'],
      order: data['order'],
      series: (data['series'] as List<dynamic>? ?? []).map((doc) => Series.fromFirestore(doc)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name':name,
      'variant': variant,
      'order': order,
      'series': series.map((x) => x.toMap()).toList(),
    };
  }
}

class Series {
  String? id;
  int reps;
  int sets;
  String intensity;
  String rpe;
  double weight;
 // bool done;
  //int reps_done;
  //double weight_done;
  //int order;

  Series({
    this.id,
    required this.reps,
    required this.sets,
    required this.intensity,
    required this.rpe,
    required this.weight,
   // required this.done,
   // required this.reps_done,
    //required this.weight_done,
    //required this.order,
  });

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id'],
      reps: map['reps'],
      sets: map['sets'],
      intensity: map['intensity'],
      rpe: map['rpe'],
      weight: map['weight'].toDouble(),
    //  done: map['done'],
     // reps_done: map['reps_done'],
     // weight_done: map['weight_done'].toDouble(),
     // order: map['order'],
    );
  }

  factory Series.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Series(
      id: doc.id,
      reps: data['reps'],
      sets: data['sets'],
      intensity: data['intensity'],
      rpe: data['rpe'],
      weight: data.containsKey('weight') ? (data['weight'] ?? 0).toDouble() : 0.0, // Check for null and convert to double
    //  done: data['done'],
      //reps_done: data['reps_done'],
      //weight_done: data.containsKey('weight_done') ? (data['weight_done'] ?? 0).toDouble() : 0.0, // Check for null and convert
      //order: data['order'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
     // 'done': done,
      //'reps_done': reps_done,
      //'weight_done': weight_done,
      //'order': order,
    };
  }
}
