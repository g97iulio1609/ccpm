import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/training_model.dart';
import '../models/week_model.dart';
import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../models/series_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TrainingProgram>> streamTrainingPrograms() {
    return _db.collection('programs').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => TrainingProgram.fromFirestore(doc))
        .toList());
  }

  Future<String> addProgram(Map<String, dynamic> programData) async {
    DocumentReference ref = await _db.collection('programs').add(programData);
    return ref.id;
  }

  Future<void> updateProgram(
      String programId, Map<String, dynamic> programData) async {
    await _db.collection('programs').doc(programId).update(programData);
  }

  Future<void> removeProgram(String programId) async {
    WriteBatch batch = _db.batch();

    // Get all weeks related to the program
    QuerySnapshot weeksSnapshot = await _db.collection('weeks').where('programId', isEqualTo: programId).get();

    for (var weekDoc in weeksSnapshot.docs) {
      String weekId = weekDoc.id;

      // Get all workouts related to the week
      QuerySnapshot workoutsSnapshot = await _db.collection('workouts').where('weekId', isEqualTo: weekId).get();

      for (var workoutDoc in workoutsSnapshot.docs) {
        String workoutId = workoutDoc.id;

        // Get all exercises related to the workout
        QuerySnapshot exercisesSnapshot = await _db.collection('exercisesWorkout').where('workoutId', isEqualTo: workoutId).get();

        for (var exerciseDoc in exercisesSnapshot.docs) {
          String exerciseId = exerciseDoc.id;

          // Get all series related to the exercise
          QuerySnapshot seriesSnapshot = await _db.collection('series').where('exerciseId', isEqualTo: exerciseId).get();

          for (var seriesDoc in seriesSnapshot.docs) {
            batch.delete(seriesDoc.reference);
          }

          batch.delete(exerciseDoc.reference);
        }

        batch.delete(workoutDoc.reference);
      }

      batch.delete(weekDoc.reference);
    }

    batch.delete(_db.collection('programs').doc(programId));

    await batch.commit();
  }

  Future<TrainingProgram> fetchTrainingProgram(String programId) async {
    DocumentSnapshot programSnapshot = await _db.collection('programs').doc(programId).get();
    if (!programSnapshot.exists) {
      throw Exception('Training program not found');
    }
    TrainingProgram program = TrainingProgram.fromFirestore(programSnapshot);

    QuerySnapshot weeksSnapshot = await _db
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .orderBy('number')
        .get();
    List<Week> weeks = weeksSnapshot.docs.map((doc) => Week.fromFirestore(doc)).toList();

    List<Future<QuerySnapshot>> workoutsFutures = weeks.map((week) {
      return _db
          .collection('workouts')
          .where('weekId', isEqualTo: week.id)
          .orderBy('order')
          .get();
    }).toList();
    List<QuerySnapshot> workoutsSnapshots = await Future.wait(workoutsFutures);

    for (int i = 0; i < weeks.length; i++) {
      Week week = weeks[i];
      List<Workout> workouts =
          workoutsSnapshots[i].docs.map((doc) => Workout.fromFirestore(doc)).toList();

      List<Future<QuerySnapshot>> exercisesFutures = workouts.map((workout) {
        return _db
            .collection('exercisesWorkout')
            .where('workoutId', isEqualTo: workout.id)
            .orderBy('order')
            .get();
      }).toList();
      List<QuerySnapshot> exercisesSnapshots = await Future.wait(exercisesFutures);

      for (int j = 0; j < workouts.length; j++) {
        Workout workout = workouts[j];
        List<Exercise> exercises = exercisesSnapshots[j].docs.map((doc) {
          Exercise exercise = Exercise.fromFirestore(doc);
          exercise.superSetId = (doc.data() as Map<String, dynamic>)?['superSetId'];
          return exercise;
        }).toList();

        List<Future<QuerySnapshot>> seriesFutures = exercises.map((exercise) {
          return _db
              .collection('series')
              .where('exerciseId', isEqualTo: exercise.id)
              .orderBy('order')
              .get();
        }).toList();
        List<QuerySnapshot> seriesSnapshots = await Future.wait(seriesFutures);

        for (int k = 0; k < exercises.length; k++) {
          Exercise exercise = exercises[k];
          List<Series> seriesList =
              seriesSnapshots[k].docs.map((doc) => Series.fromFirestore(doc)).toList();
          exercise.series = seriesList;
        }

        workout.exercises = exercises;
      }

      week.workouts = workouts;
    }

    program.weeks = weeks;
    return program;
  }

  Future<void> addOrUpdateTrainingProgram(TrainingProgram program) async {
    WriteBatch batch = _db.batch();
    String programId = program.id?.trim().isEmpty ?? true
        ? _db.collection('programs').doc().id
        : program.id!;
    program.id = programId;
    DocumentReference programRef = _db.collection('programs').doc(programId);
    batch.set(
      programRef,
      program.toMap(),
      SetOptions(merge: true),
    );

    for (var week in program.weeks) {
      String weekId = week.id?.trim().isEmpty ?? true
          ? _db.collection('weeks').doc().id
          : week.id!;
      week.id = weekId;
      DocumentReference weekRef = _db.collection('weeks').doc(weekId);
      batch.set(
        weekRef,
        {
          'number': week.number,
          'programId': programId,
        },
        SetOptions(merge: true),
      );

      for (var workout in week.workouts) {
        String workoutId = workout.id?.trim().isEmpty ?? true
            ? _db.collection('workouts').doc().id
            : workout.id!;
        workout.id = workoutId;
        DocumentReference workoutRef = _db.collection('workouts').doc(workoutId);
        batch.set(
          workoutRef,
          {
            'order': workout.order,
            'weekId': weekId,
          },
          SetOptions(merge: true),
        );

        for (var exercise in workout.exercises) {
          String exerciseId = exercise.id?.trim().isEmpty ?? true
              ? _db.collection('exercisesWorkout').doc().id
              : exercise.id!;
          exercise.id = exerciseId;
          DocumentReference exerciseRef =
              _db.collection('exercisesWorkout').doc(exerciseId);
          batch.set(
            exerciseRef,
            {
              'name': exercise.name,
              'order': exercise.order,
              'variant': exercise.variant,
              'workoutId': workoutId,
              'exerciseId': exercise.exerciseId,
              'superSetId': exercise.superSetId,
            },
            SetOptions(merge: true),
          );

          for (int i = 0; i < exercise.series.length; i++) {
            var series = exercise.series[i];
            String seriesId = series.serieId?.trim().isEmpty ?? true
                ? _db.collection('series').doc().id
                : series.serieId!;
            series.serieId = seriesId;
            DocumentReference seriesRef = _db.collection('series').doc(seriesId);
            batch.set(
              seriesRef,
              {
                'reps': series.reps,
                'sets': series.sets,
                'intensity': series.intensity,
                'rpe': series.rpe,
                'weight': series.weight,
                'exerciseId': exerciseId,
                'serieId': seriesId,
                'order': i + 1,
                'done': series.done,
                'reps_done': series.reps_done,
                'weight_done': series.weight_done,
              },
              SetOptions(merge: true),
            );
          }
        }
      }
    }

    await batch.commit();
  }

  Future<void> _removeRelatedData(String collection, String field, String id) async {
    var snapshot = await _db.collection(collection).where(field, isEqualTo: id).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> removeToDeleteItems(TrainingProgram program) async {
    WriteBatch batch = _db.batch();

    for (String weekId in program.trackToDeleteWeeks) {
      DocumentReference weekRef = _db.collection('weeks').doc(weekId);
      batch.delete(weekRef);
    }

    for (String workoutId in program.trackToDeleteWorkouts) {
      DocumentReference workoutRef = _db.collection('workouts').doc(workoutId);
      batch.delete(workoutRef);
    }

    for (String exerciseId in program.trackToDeleteExercises) {
      DocumentReference exerciseRef =
          _db.collection('exercisesWorkout').doc(exerciseId);
      batch.delete(exerciseRef);
    }

    for (String seriesId in program.trackToDeleteSeries) {
      DocumentReference seriesRef = _db.collection('series').doc(seriesId);
      batch.delete(seriesRef);
    }

    await batch.commit();
  }
}
