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
import 'package:alphanessone/trainingBuilder/models/series_model.dart';

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
      case 'add_week':
        return await _handleAddWeek(userId);
      case 'remove_week':
        final weekNumber = interpretation['weekNumber'] as int?;
        return await _handleRemoveWeek(userId, weekNumber);
      case 'add_workout':
        final weekNumber = interpretation['weekNumber'] as int?;
        return await _handleAddWorkout(userId, weekNumber);
      case 'remove_workout':
        final weekNumber = interpretation['weekNumber'] as int?;
        final workoutOrder = interpretation['workoutOrder'] as int?;
        return await _handleRemoveWorkout(userId, weekNumber, workoutOrder);
      case 'add_exercise':
        final weekNumber = interpretation['weekNumber'] as int?;
        final workoutOrder = interpretation['workoutOrder'] as int?;
        final exerciseName = interpretation['exerciseName'] as String?;
        final exerciseType = interpretation['exerciseType'] as String?;
        return await _handleAddExercise(
            userId, weekNumber, workoutOrder, exerciseName, exerciseType);
      case 'remove_exercise':
        final weekNumber = interpretation['weekNumber'] as int?;
        final workoutOrder = interpretation['workoutOrder'] as int?;
        final exerciseName = interpretation['exerciseName'] as String?;
        return await _handleRemoveExercise(
            userId, weekNumber, workoutOrder, exerciseName);
      case 'add_series':
        final weekNumber = interpretation['weekNumber'] as int?;
        final workoutOrder = interpretation['workoutOrder'] as int?;
        final exerciseName = interpretation['exerciseName'] as String?;
        final sets = interpretation['sets'] as int?;
        final reps = interpretation['reps'] as int?;
        final weight = interpretation['weight'] as num?;
        final intensity = interpretation['intensity'] as String?;
        return await _handleAddSeries(userId, weekNumber, workoutOrder,
            exerciseName, sets, reps, weight, intensity);
      case 'remove_series':
        final weekNumber = interpretation['weekNumber'] as int?;
        final workoutOrder = interpretation['workoutOrder'] as int?;
        final exerciseName = interpretation['exerciseName'] as String?;
        final seriesOrder = interpretation['seriesOrder'] as int?;
        return await _handleRemoveSeries(
            userId, weekNumber, workoutOrder, exerciseName, seriesOrder);
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
                        serieId: '',
                        sets: seriesData['sets'] ?? 0,
                        reps: seriesData['reps'] ?? 0,
                        weight: (seriesData['weight'] ?? 0).toDouble(),
                        intensity: seriesData['intensity'] ?? '',
                        order: seriesData['order'] ?? 0,
                        done: false,
                        reps_done: 0,
                        weight_done: 0,
                        maxReps: seriesData['reps'] ?? 0,
                        maxSets: seriesData['sets'] ?? 0,
                        maxWeight: (seriesData['weight'] ?? 0).toDouble(),
                        maxIntensity: seriesData['intensity'] ?? '',
                        maxRpe: '',
                        rpe: '',
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

  Future<String?> _handleAddWeek(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      // Troviamo il numero più alto tra le settimane esistenti
      int maxWeekNumber = 0;
      for (var week in program.weeks) {
        if (week.number > maxWeekNumber) {
          maxWeekNumber = week.number;
        }
      }

      final newWeekNumber = maxWeekNumber + 1;
      final week = Week(number: newWeekNumber);
      program.weeks.add(week);

      await _trainingService.addOrUpdateTrainingProgram(program);
      return 'Ho aggiunto la settimana $newWeekNumber al tuo programma.';
    } catch (e) {
      _logger.e('Error adding week', error: e);
      return 'Si è verificato un errore durante l\'aggiunta della settimana.';
    }
  }

  Future<String?> _handleRemoveWeek(String userId, int? weekNumber) async {
    if (weekNumber == null) {
      return 'Specifica il numero della settimana da rimuovere.';
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      final weekIndex = program.weeks.indexWhere((w) => w.number == weekNumber);
      if (weekIndex == -1) {
        return 'Settimana $weekNumber non trovata.';
      }

      program.trackToDeleteWeeks.add(program.weeks[weekIndex].id!);
      program.weeks.removeAt(weekIndex);

      await _trainingService.addOrUpdateTrainingProgram(program);
      return 'Ho rimosso la settimana $weekNumber dal tuo programma.';
    } catch (e) {
      _logger.e('Error removing week', error: e);
      return 'Si è verificato un errore durante la rimozione della settimana.';
    }
  }

  Future<String?> _handleAddWorkout(String userId, int? weekNumber) async {
    if (weekNumber == null) {
      return 'Specifica il numero della settimana per aggiungere l\'allenamento.';
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      final weekIndex = program.weeks.indexWhere((w) => w.number == weekNumber);
      if (weekIndex == -1) {
        return 'Settimana $weekNumber non trovata.';
      }

      final week = program.weeks[weekIndex];

      // Troviamo l'ordine più alto tra gli allenamenti esistenti
      int maxOrder = 0;
      for (var workout in week.workouts) {
        if (workout.order > maxOrder) {
          maxOrder = workout.order;
        }
      }

      final newWorkoutOrder = maxOrder + 1;
      final workout = Workout(
        order: newWorkoutOrder,
        name: 'Allenamento $newWorkoutOrder',
      );
      week.workouts.add(workout);

      await _trainingService.addOrUpdateTrainingProgram(program);
      return 'Ho aggiunto l\'allenamento $newWorkoutOrder alla settimana $weekNumber.';
    } catch (e) {
      _logger.e('Error adding workout', error: e);
      return 'Si è verificato un errore durante l\'aggiunta dell\'allenamento.';
    }
  }

  Future<String?> _handleRemoveWorkout(
      String userId, int? weekNumber, int? workoutOrder) async {
    if (weekNumber == null || workoutOrder == null) {
      return 'Specifica il numero della settimana e l\'ordine dell\'allenamento da rimuovere.';
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      final weekIndex = program.weeks.indexWhere((w) => w.number == weekNumber);
      if (weekIndex == -1) {
        return 'Settimana $weekNumber non trovata.';
      }

      final week = program.weeks[weekIndex];
      final workoutIndex =
          week.workouts.indexWhere((w) => w.order == workoutOrder);
      if (workoutIndex == -1) {
        return 'Allenamento $workoutOrder non trovato nella settimana $weekNumber.';
      }

      // Salva l'ID dell'allenamento da rimuovere
      if (week.workouts[workoutIndex].id != null) {
        program.trackToDeleteWorkouts.add(week.workouts[workoutIndex].id!);
      }

      // Rimuovi l'allenamento
      week.workouts.removeAt(workoutIndex);

      // Riordina gli allenamenti rimanenti mantenendo l'ordine sequenziale
      for (var i = 0; i < week.workouts.length; i++) {
        if (week.workouts[i].order > workoutOrder) {
          week.workouts[i].order = week.workouts[i].order - 1;
        }
      }

      await _trainingService.addOrUpdateTrainingProgram(program);
      return 'Ho rimosso l\'allenamento $workoutOrder dalla settimana $weekNumber.';
    } catch (e) {
      _logger.e('Error removing workout', error: e);
      return 'Si è verificato un errore durante la rimozione dell\'allenamento.';
    }
  }

  Future<String?> _handleAddExercise(String userId, int? weekNumber,
      int? workoutOrder, String? exerciseName, String? exerciseType) async {
    if (weekNumber == null || workoutOrder == null || exerciseName == null) {
      return 'Specifica il numero della settimana, l\'ordine dell\'allenamento e il nome dell\'esercizio.';
    }

    try {
      // Normalizza il nome dell'esercizio (rimuovi spazi extra e converti in lowercase)
      final normalizedExerciseName =
          exerciseName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      // 1. Prima cerchiamo l'exerciseId nella collection Exercises
      final exercisesQuery = await _firestore.collection('exercises').get();

      String? matchedExerciseId;
      String matchedType = exerciseType ?? '';
      String matchedName = exerciseName;

      // Cerca il miglior match tra gli esercizi
      for (var doc in exercisesQuery.docs) {
        final dbExerciseName = doc.data()['name'] as String? ?? '';
        final normalizedDbName =
            dbExerciseName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

        if (normalizedDbName == normalizedExerciseName) {
          matchedExerciseId = doc.id;
          matchedName = dbExerciseName; // Usa il nome esatto dal database
          if (exerciseType == null || exerciseType.isEmpty) {
            matchedType = doc.data()['type'] ?? '';
          }
          break;
        }
      }

      if (matchedExerciseId == null) {
        _logger.w('Nessun esercizio trovato con il nome: $exerciseName');
        return 'Non ho trovato l\'esercizio "$exerciseName" nel database. Assicurati che il nome sia corretto.';
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      final weekIndex = program.weeks.indexWhere((w) => w.number == weekNumber);
      if (weekIndex == -1) {
        return 'Settimana $weekNumber non trovata.';
      }

      final week = program.weeks[weekIndex];
      final workoutIndex =
          week.workouts.indexWhere((w) => w.order == workoutOrder);
      if (workoutIndex == -1) {
        return 'Allenamento $workoutOrder non trovato nella settimana $weekNumber.';
      }

      final workout = week.workouts[workoutIndex];

      // Verifica se l'esercizio esiste già nell'allenamento (case insensitive)
      final existingExerciseIndex = workout.exercises.indexWhere((e) =>
          e.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ==
          normalizedExerciseName);

      if (existingExerciseIndex != -1) {
        return 'L\'esercizio "$matchedName" è già presente nell\'allenamento $workoutOrder della settimana $weekNumber.';
      }

      // Troviamo l'ordine più alto tra gli esercizi esistenti
      int maxOrder = 0;
      for (var exercise in workout.exercises) {
        if (exercise.order > maxOrder) {
          maxOrder = exercise.order;
        }
      }

      final exercise = Exercise(
        name: matchedName,
        type: matchedType,
        variant: '',
        order: maxOrder + 1,
        exerciseId: matchedExerciseId,
      );
      workout.exercises.add(exercise);

      await _trainingService.addOrUpdateTrainingProgram(program);
      return 'Ho aggiunto l\'esercizio "$matchedName" all\'allenamento $workoutOrder della settimana $weekNumber.';
    } catch (e) {
      _logger.e('Error adding exercise', error: e);
      return 'Si è verificato un errore durante l\'aggiunta dell\'esercizio.';
    }
  }

  Future<String?> _handleRemoveExercise(String userId, int? weekNumber,
      int? workoutOrder, String? exerciseName) async {
    if (weekNumber == null || workoutOrder == null || exerciseName == null) {
      return 'Specifica il numero della settimana, l\'ordine dell\'allenamento e il nome dell\'esercizio da rimuovere.';
    }

    try {
      // Normalizza il nome dell'esercizio
      final normalizedExerciseName =
          exerciseName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      final weekIndex = program.weeks.indexWhere((w) => w.number == weekNumber);
      if (weekIndex == -1) {
        return 'Settimana $weekNumber non trovata.';
      }

      final week = program.weeks[weekIndex];
      final workoutIndex =
          week.workouts.indexWhere((w) => w.order == workoutOrder);
      if (workoutIndex == -1) {
        return 'Allenamento $workoutOrder non trovato nella settimana $weekNumber.';
      }

      final workout = week.workouts[workoutIndex];
      final exerciseIndex = workout.exercises.indexWhere((e) =>
          e.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ==
          normalizedExerciseName);
      if (exerciseIndex == -1) {
        return 'Esercizio "$exerciseName" non trovato nell\'allenamento $workoutOrder della settimana $weekNumber.';
      }

      final exerciseOrder = workout.exercises[exerciseIndex].order;
      final originalName = workout.exercises[exerciseIndex].name;

      // Salva l'ID dell'esercizio da rimuovere
      if (workout.exercises[exerciseIndex].id != null) {
        program.trackToDeleteExercises
            .add(workout.exercises[exerciseIndex].id!);
      }

      // Rimuovi l'esercizio
      workout.exercises.removeAt(exerciseIndex);

      // Riordina gli esercizi rimanenti mantenendo l'ordine sequenziale
      for (var exercise in workout.exercises) {
        if (exercise.order > exerciseOrder) {
          exercise.order = exercise.order - 1;
        }
      }

      await _trainingService.addOrUpdateTrainingProgram(program);
      return 'Ho rimosso l\'esercizio "$originalName" dall\'allenamento $workoutOrder della settimana $weekNumber.';
    } catch (e) {
      _logger.e('Error removing exercise', error: e);
      return 'Si è verificato un errore durante la rimozione dell\'esercizio.';
    }
  }

  Future<String?> _handleAddSeries(
      String userId,
      int? weekNumber,
      int? workoutOrder,
      String? exerciseName,
      int? sets,
      int? reps,
      num? weight,
      String? intensity) async {
    if (weekNumber == null ||
        workoutOrder == null ||
        exerciseName == null ||
        sets == null ||
        reps == null) {
      return 'Specifica il numero della settimana, l\'ordine dell\'allenamento, il nome dell\'esercizio, il numero di serie e ripetizioni.';
    }

    try {
      // Normalizza il nome dell'esercizio
      final normalizedExerciseName =
          exerciseName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      final weekIndex = program.weeks.indexWhere((w) => w.number == weekNumber);
      if (weekIndex == -1) {
        return 'Settimana $weekNumber non trovata.';
      }

      final week = program.weeks[weekIndex];
      final workoutIndex =
          week.workouts.indexWhere((w) => w.order == workoutOrder);
      if (workoutIndex == -1) {
        return 'Allenamento $workoutOrder non trovato nella settimana $weekNumber.';
      }

      final workout = week.workouts[workoutIndex];
      final exerciseIndex = workout.exercises.indexWhere((e) =>
          e.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ==
          normalizedExerciseName);
      if (exerciseIndex == -1) {
        return 'Esercizio "$exerciseName" non trovato nell\'allenamento $workoutOrder della settimana $weekNumber.';
      }

      final exercise = workout.exercises[exerciseIndex];

      // Troviamo l'ordine più alto tra le serie esistenti
      int maxOrder = 0;
      for (var series in exercise.series) {
        if (series.order > maxOrder) {
          maxOrder = series.order;
        }
      }

      // Parsing dei valori con range
      int minReps = reps;
      int? maxReps;
      double minWeight = (weight ?? 0).toDouble();
      double? maxWeight;
      String minIntensity = intensity ?? '';
      String? maxIntensity;

      // Controlla se reps contiene un range (es: "4-6" o "4/6")
      if (reps.toString().contains(RegExp(r'[-/]'))) {
        final parts = reps.toString().split(RegExp(r'[-/]'));
        if (parts.length == 2) {
          minReps = int.parse(parts[0].trim());
          maxReps = int.parse(parts[1].trim());
        }
      }

      // Controlla se weight contiene un range
      if (weight != null && weight.toString().contains(RegExp(r'[-/]'))) {
        final parts = weight.toString().split(RegExp(r'[-/]'));
        if (parts.length == 2) {
          minWeight = double.parse(parts[0].trim());
          maxWeight = double.parse(parts[1].trim());
        }
      }

      // Controlla se intensity contiene un range
      if (intensity != null && intensity.contains(RegExp(r'[-/]'))) {
        final parts = intensity.split(RegExp(r'[-/]'));
        if (parts.length == 2) {
          minIntensity = parts[0].trim();
          maxIntensity = parts[1].trim();
        }
      }

      // Crea il numero specificato di serie
      for (var i = 0; i < sets; i++) {
        final series = Series(
          serieId: '',
          sets:
              1, // Ogni serie ha set=1 perché stiamo creando 'sets' numero di serie
          reps: minReps,
          weight: minWeight,
          intensity: minIntensity,
          order: maxOrder + i + 1,
          done: false,
          reps_done: 0,
          weight_done: 0,
          maxReps: maxReps, // Se non specificato, rimane null
          maxSets: 1,
          maxWeight: maxWeight, // Se non specificato, rimane null
          maxIntensity: maxIntensity, // Se non specificato, rimane null
          maxRpe: '',
          rpe: '',
        );
        exercise.series.add(series);
      }

      await _trainingService.addOrUpdateTrainingProgram(program);
      String response = 'Ho aggiunto $sets serie di ';

      // Formatta la risposta in base ai range
      if (maxReps != null) {
        response += '$minReps-$maxReps';
      } else {
        response += '$minReps';
      }
      response += ' ripetizioni';

      if (weight != null) {
        if (maxWeight != null) {
          response += ' @${minWeight}-${maxWeight}kg';
        } else {
          response += ' @${minWeight}kg';
        }
      }

      if (intensity != null && intensity.isNotEmpty) {
        if (maxIntensity != null && maxIntensity.isNotEmpty) {
          response += ' $minIntensity-$maxIntensity';
        } else {
          response += ' $minIntensity';
        }
      }

      response +=
          ' all\'esercizio "$exerciseName" nell\'allenamento $workoutOrder della settimana $weekNumber.';
      return response;
    } catch (e) {
      _logger.e('Error adding series', error: e);
      return 'Si è verificato un errore durante l\'aggiunta della serie.';
    }
  }

  Future<String?> _handleRemoveSeries(String userId, int? weekNumber,
      int? workoutOrder, String? exerciseName, int? seriesOrder) async {
    if (weekNumber == null ||
        workoutOrder == null ||
        exerciseName == null ||
        seriesOrder == null) {
      return 'Specifica il numero della settimana, l\'ordine dell\'allenamento, il nome dell\'esercizio e l\'ordine della serie da rimuovere.';
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentProgramId = userDoc.data()?['currentProgram'] as String?;

      if (currentProgramId == null) {
        return 'Non hai un programma di allenamento attivo.';
      }

      final program =
          await _trainingService.fetchTrainingProgram(currentProgramId);
      if (program == null) {
        return 'Programma non trovato.';
      }

      final weekIndex = program.weeks.indexWhere((w) => w.number == weekNumber);
      if (weekIndex == -1) {
        return 'Settimana $weekNumber non trovata.';
      }

      final week = program.weeks[weekIndex];
      final workoutIndex =
          week.workouts.indexWhere((w) => w.order == workoutOrder);
      if (workoutIndex == -1) {
        return 'Allenamento $workoutOrder non trovato nella settimana $weekNumber.';
      }

      final workout = week.workouts[workoutIndex];
      final exerciseIndex = workout.exercises.indexWhere(
          (e) => e.name.toLowerCase() == exerciseName.toLowerCase());
      if (exerciseIndex == -1) {
        return 'Esercizio "$exerciseName" non trovato nell\'allenamento $workoutOrder della settimana $weekNumber.';
      }

      final exercise = workout.exercises[exerciseIndex];
      final seriesIndex =
          exercise.series.indexWhere((s) => s.order == seriesOrder);
      if (seriesIndex == -1) {
        return 'Serie $seriesOrder non trovata per l\'esercizio "$exerciseName".';
      }

      // Salva l'ID della serie da rimuovere
      if (exercise.series[seriesIndex].serieId.isNotEmpty) {
        program.trackToDeleteSeries.add(exercise.series[seriesIndex].serieId);
      }

      // Rimuovi la serie
      exercise.series.removeAt(seriesIndex);

      // Riordina le serie rimanenti mantenendo l'ordine sequenziale
      for (var series in exercise.series) {
        if (series.order > seriesOrder) {
          series.order = series.order - 1;
        }
      }

      await _trainingService.addOrUpdateTrainingProgram(program);
      return 'Ho rimosso la serie $seriesOrder dall\'esercizio "$exerciseName" nell\'allenamento $workoutOrder della settimana $weekNumber.';
    } catch (e) {
      _logger.e('Error removing series', error: e);
      return 'Si è verificato un errore durante la rimozione della serie.';
    }
  }
}
