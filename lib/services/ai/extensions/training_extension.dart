// lib/services/ai/extensions/training_extension.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/models/workout_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'ai_extension.dart';
import 'package:alphanessone/trainingBuilder/services/training_services.dart';

class TrainingExtension implements AIExtension {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(
    printer: PrettyPrinter(),
  );
  final TrainingProgramService _trainingService =
      TrainingProgramService(FirestoreService());

  @override
  Future<bool> canHandle(Map<String, dynamic> interpretation) async {
    return interpretation['featureType'] == 'training';
  }

  @override
  Future<String?> handle(Map<String, dynamic> interpretation, String userId,
      UserModel user) async {
    final action = interpretation['action'] as String?;
    _logger.d('Handling training action: $action');

    switch (action) {
      case 'create_program':
        return await _handleCreateProgram(interpretation, userId);
      case 'query_program':
        final bool current = interpretation['current'] ?? false;
        return await _handleQueryProgram(userId, current: current);
      case 'current_program_info':
        return await _handleCurrentProgramInfo(userId);
      default:
        _logger.w('Unrecognized action for training: $action');
        return 'Azione non riconosciuta per training.';
    }
  }

  Future<String?> _handleCreateProgram(
      Map<String, dynamic> interpretation, String userId) async {
    _logger.i('Creating training program with interpretation: $interpretation');
    try {
      final program = TrainingProgram(
        name: interpretation['name'] ?? 'Nuovo Programma',
        description: interpretation['description'] ?? '',
        athleteId: userId,
        mesocycleNumber: interpretation['weeks']?.length ?? 0,
        status: 'private',
      );

      final programRef =
          await _firestore.collection('programs').add(program.toMap());
      program.id = programRef.id;

      if (interpretation['weeks'] != null) {
        for (var weekData in interpretation['weeks']) {
          final week = Week(
            number: weekData['number'],
          );

          final weekRef =
              await programRef.collection('weeks').add(week.toMap());
          week.id = weekRef.id;

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

      _logger.i('Training program "${program.name}" created successfully.');
      return 'Ho creato il programma di allenamento "${program.name}" con ${program.mesocycleNumber} settimane.';
    } catch (e, stackTrace) {
      _logger.e('Error creating training program',
          error: e, stackTrace: stackTrace);
      return 'Si è verificato un errore durante la creazione del programma.';
    }
  }

  Future<String?> _handleQueryProgram(String userId,
      {bool current = false}) async {
    _logger
        .i('Querying training programs for user: $userId, current: $current');
    try {
      if (current) {
        // 1. Prima ottieni il documento dell'utente per il currentProgram
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final currentProgramId = userDoc.data()?['currentProgram'] as String?;

        if (currentProgramId == null) {
          _logger.d('No current program ID found');
          return 'Non hai un programma di allenamento attivo al momento.';
        }

        // 2. Recupera il programma usando il TrainingProgramService
        final program =
            await _trainingService.fetchTrainingProgram(currentProgramId);

        if (program == null) {
          _logger.d('Current program not found');
          return 'Non ho trovato il tuo programma di allenamento attuale.';
        }

        final buffer = StringBuffer();
        buffer.writeln('Il tuo programma attuale:');
        buffer.writeln('• ${program.name}');
        if (program.description.isNotEmpty) {
          buffer.writeln('  ${program.description}');
        }
        buffer.writeln('\nSettimane:');

        for (var week in program.weeks) {
          buffer.writeln('\nSettimana ${week.number}:');
          for (var workout in week.workouts) {
            buffer.writeln('  Allenamento ${workout.order + 1}:');
            for (var exercise in workout.exercises) {
              buffer.writeln('    • ${exercise.name}');
              for (var series in exercise.series) {
                buffer.write('      - ${series.sets}x${series.reps}');
                if (series.weight > 0) {
                  buffer.write(' @${series.weight}kg');
                }
                if (series.intensity.isNotEmpty && series.intensity != '0') {
                  buffer.write(' ${series.intensity}');
                }
                buffer.writeln();
              }
            }
          }
        }

        return buffer.toString();
      } else {
        // Query per tutti i programmi dell'utente
        final programsQuery = await _firestore
            .collection('programs')
            .where('athleteId', isEqualTo: userId)
            .get();

        if (programsQuery.docs.isEmpty) {
          return 'Non hai ancora nessun programma di allenamento.';
        }

        final buffer = StringBuffer();
        buffer.writeln('I tuoi programmi di allenamento:');

        for (var doc in programsQuery.docs) {
          final program = TrainingProgram.fromFirestore(doc);
          buffer.writeln(
              '\n• ${program.name} (${program.mesocycleNumber} settimane)');
          if (program.description.isNotEmpty) {
            buffer.writeln('  ${program.description}');
          }
        }

        return buffer.toString();
      }
    } catch (e, stackTrace) {
      _logger.e('Error querying training programs',
          error: e, stackTrace: stackTrace);
      return 'Si è verificato un errore durante la ricerca dei programmi.';
    }
  }

  Future<String?> _handleCurrentProgramInfo(String userId) async {
    _logger.i('Retrieving current training program info for user: $userId');
    try {
      final programsQuery = await _firestore
          .collection('programs')
          .where('athleteId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (programsQuery.docs.isEmpty) {
        final response =
            'Non hai un programma di allenamento attivo al momento.';
        _logger.d(response);
        return response;
      }

      final program = TrainingProgram.fromFirestore(programsQuery.docs.first);

      final buffer = StringBuffer();
      buffer.writeln('Il tuo programma attuale: ${program.name}');
      if (program.description.isNotEmpty) {
        buffer.writeln('Descrizione: ${program.description}');
      }
      buffer.writeln('Durata: ${program.mesocycleNumber} settimane');

      // Aggiungi ulteriori dettagli se necessario

      final result = buffer.toString();
      _logger.d('Current training program info: $result');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving current program',
          error: e, stackTrace: stackTrace);
      return 'Si è verificato un errore durante la ricerca del programma attuale.';
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
