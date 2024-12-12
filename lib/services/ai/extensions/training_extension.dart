import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/models/workout_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'ai_extension.dart';

class TrainingExtension implements AIExtension {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  @override
  Future<bool> canHandle(Map<String, dynamic> interpretation) async {
    return interpretation['featureType'] == 'training';
  }

  @override
  Future<String?> handle(Map<String, dynamic> interpretation, String userId,
      UserModel user) async {
    final action = interpretation['action'];
    switch (action) {
      case 'create_program':
        return await _handleCreateProgram(interpretation, userId);
      case 'query_program':
        return await _handleQueryProgram(interpretation, userId);
      default:
        return null;
    }
  }

  Future<String?> _handleCreateProgram(
      Map<String, dynamic> interpretation, String userId) async {
    try {
      final program = TrainingProgram(
        name: interpretation['name'] ?? 'Nuovo Programma',
        description: interpretation['description'] ?? '',
        athleteId: userId,
        mesocycleNumber: interpretation['weeks']?.length ?? 0,
        status: 'private',
      );

      // Crea il programma
      final programRef =
          await _firestore.collection('programs').add(program.toMap());
      program.id = programRef.id;

      // Crea le settimane
      if (interpretation['weeks'] != null) {
        for (var weekData in interpretation['weeks']) {
          final week = Week(
            number: weekData['number'],
          );

          final weekRef =
              await programRef.collection('weeks').add(week.toMap());
          week.id = weekRef.id;

          // Crea i workout per ogni settimana
          if (weekData['workouts'] != null) {
            for (var workoutData in weekData['workouts']) {
              final workout = Workout(
                order: workoutData['order'] ?? 0,
                name: workoutData['name'] ??
                    'Allenamento ${workoutData['order']}',
              );

              final workoutRef =
                  await weekRef.collection('workouts').add(workout.toMap());
              workout.id = workoutRef.id;

              // Crea gli esercizi per ogni workout
              if (workoutData['exercises'] != null) {
                for (var exerciseData in workoutData['exercises']) {
                  final exercise = Exercise(
                    name: exerciseData['name'],
                    type: exerciseData['type'] ?? '',
                    variant: exerciseData['variant'] ?? '',
                    order: exerciseData['order'] ?? 0,
                  );

                  final exerciseRef = await workoutRef
                      .collection('exercises')
                      .add(exercise.toMap());
                  exercise.id = exerciseRef.id;

                  // Crea le serie per ogni esercizio
                  if (exerciseData['series'] != null) {
                    for (var seriesData in exerciseData['series']) {
                      final series = Series(
                        reps: seriesData['reps'] ?? 0,
                        weight: seriesData['weight'] ?? 0,
                        intensity: seriesData['intensity'] ?? '0',
                        order: seriesData['order'] ?? 0,
                      );

                      await exerciseRef
                          .collection('series')
                          .add(series.toMap());
                    }
                  }
                }
              }
            }
          }
        }
      }

      return 'Ho creato il programma di allenamento "${program.name}" con ${program.mesocycleNumber} settimane.';
    } catch (e) {
      _logger.e('Error creating training program', error: e);
      return 'Si è verificato un errore durante la creazione del programma.';
    }
  }

  Future<String?> _handleQueryProgram(
      Map<String, dynamic> interpretation, String userId) async {
    try {
      final targetUserId = interpretation['userId'] ?? userId;

      final programsQuery = await _firestore
          .collection('programs')
          .where('userId', isEqualTo: targetUserId)
          .get();

      if (programsQuery.docs.isEmpty) {
        return 'Non hai ancora nessun programma di allenamento.';
      }

      final buffer = StringBuffer('I tuoi programmi di allenamento:\n');
      for (var doc in programsQuery.docs) {
        final program = TrainingProgram.fromFirestore(doc);
        buffer.writeln(
            '- ${program.name} (${program.mesocycleNumber} settimane)');
      }

      return buffer.toString();
    } catch (e) {
      _logger.e('Error querying training programs', error: e);
      return 'Si è verificato un errore durante la ricerca dei programmi.';
    }
  }
}

class Series {
  final int reps;
  final num weight;
  final String intensity;
  final int order;

  Series({
    required this.reps,
    required this.weight,
    required this.intensity,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
      'intensity': intensity,
      'order': order,
    };
  }
}
