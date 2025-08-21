import 'package:alphanessone/shared/shared.dart'
    hide ValidationUtils, ModelUtils, ExerciseRepository;
import '../../../ExerciseRecords/exercise_record_services.dart';
import '../../../shared/services/weight_calculation_service.dart';
import '../../shared/utils/validation_utils.dart' as local_validation_utils;
import '../../shared/utils/model_utils.dart' as local_model_utils;
import '../../utility_functions.dart';

/// Business service per le operazioni sugli esercizi
/// Segue il principio Single Responsibility
class ExerciseBusinessService {
  final ExerciseRecordService _exerciseRecordService;
  final WeightCalculationService _weightCalculationService;

  ExerciseBusinessService({required ExerciseRecordService exerciseRecordService})
    : _exerciseRecordService = exerciseRecordService,
      _weightCalculationService = WeightCalculationService(
        exerciseRecordService: exerciseRecordService,
      );

  // Getter pubblico per permettere l'accesso dall'esterno
  ExerciseRecordService get exerciseRecordService => _exerciseRecordService;

  /// Aggiunge un esercizio al workout
  Future<void> addExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    Exercise exercise,
  ) async {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Indici non validi per aggiunta esercizio');
    }

    if (!local_validation_utils.ValidationUtils.isValidExercise(exercise)) {
      throw ArgumentError('Dati esercizio non validi');
    }

    final exerciseToAdd = exercise.copyWith(
      id: null,
      order: program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1,
      weekProgressions: List.generate(program.weeks.length, (_) => []),
    );

    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exerciseToAdd);

    if (exerciseToAdd.exerciseId != null) {
      await updateExerciseWeights(program, exerciseToAdd.exerciseId!, exerciseToAdd.type);
    }
  }

  /// Rimuove un esercizio dal workout
  void removeExercise(TrainingProgram program, int weekIndex, int workoutIndex, int exerciseIndex) {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    )) {
      throw ArgumentError('Indici non validi per rimozione esercizio');
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _trackExerciseForDeletion(program, exercise);
    program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(exerciseIndex);

    final exercises = program.weeks[weekIndex].workouts[workoutIndex].exercises;
    local_model_utils.ModelUtils.updateExerciseOrders(exercises, exerciseIndex);
  }

  /// Duplica un esercizio nel workout
  void duplicateExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    )) {
      throw ArgumentError('Indici non validi per duplicazione esercizio');
    }

    final sourceExercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final duplicatedExercise = local_model_utils.ModelUtils.copyExercise(sourceExercise);

    final exerciseWithNewOrder = duplicatedExercise.copyWith(
      order: program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1,
    );
    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exerciseWithNewOrder);
  }

  /// Aggiorna un esercizio esistente
  Future<void> updateExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    Exercise updatedExercise,
  ) async {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    )) {
      throw ArgumentError('Indici non validi per aggiornamento esercizio');
    }

    if (!local_validation_utils.ValidationUtils.isValidExercise(updatedExercise)) {
      throw ArgumentError('Dati esercizio aggiornato non validi');
    }

    final originalExercise =
        program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final exerciseWithCorrectData = updatedExercise.copyWith(
      order: originalExercise.order,
      weekProgressions: originalExercise.weekProgressions,
    );

    // Verifica se l'exerciseId o il tipo sono cambiati
    final exerciseIdChanged = originalExercise.exerciseId != exerciseWithCorrectData.exerciseId;
    final exerciseTypeChanged = originalExercise.type != exerciseWithCorrectData.type;
    final shouldRecalculateWeights = exerciseIdChanged || exerciseTypeChanged;

    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] =
        exerciseWithCorrectData;

    // Ricalcola i pesi se l'esercizio o il tipo sono cambiati
    if (shouldRecalculateWeights && exerciseWithCorrectData.exerciseId != null) {
      await updateExerciseWeights(
        program,
        exerciseWithCorrectData.exerciseId!,
        exerciseWithCorrectData.type,
      );
    }
  }

  /// Aggiorna i pesi degli esercizi basandosi sui record più recenti
  Future<void> updateExerciseWeights(
    TrainingProgram program,
    String exerciseId,
    String exerciseType,
  ) async {
    if (exerciseId.isEmpty || program.athleteId.isEmpty) {
      return;
    }

    try {
      for (final week in program.weeks) {
        for (final workout in week.workouts) {
          for (int i = 0; i < workout.exercises.length; i++) {
            final exercise = workout.exercises[i];
            if (exercise.exerciseId == exerciseId) {
              // Ottieni l'esercizio aggiornato dal servizio
              final updatedExercise = await _weightCalculationService.updateExerciseWeights(
                exercise,
                program.athleteId,
                exerciseId,
                exerciseType,
              );
              // Sostituisci l'esercizio nella lista con quello aggiornato
              workout.exercises[i] = updatedExercise;
            }
          }
        }
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking the flow
      // Error logged internally for debugging purposes
    }
  }

  /// Aggiorna i pesi per un singolo esercizio del programma
  Future<void> updateSingleProgramExercise(
    TrainingProgram program,
    String exerciseId,
    String exerciseType,
  ) async {
    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (int i = 0; i < workout.exercises.length; i++) {
          final exercise = workout.exercises[i];
          if (exercise.exerciseId == exerciseId) {
            // Ottieni l'esercizio aggiornato dal servizio
            final updatedExercise = await _weightCalculationService.updateExerciseWeights(
              exercise,
              program.athleteId,
              exerciseId,
              exerciseType,
            );
            // Sostituisci l'esercizio nella lista con quello aggiornato
            workout.exercises[i] = updatedExercise;
            return; // Esce dopo aver trovato e aggiornato l'esercizio
          }
        }
      }
    }
  }

  /// Riordina gli esercizi in un workout
  void reorderExercises(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int oldIndex,
    int newIndex,
  ) {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
          program,
          weekIndex,
          workoutIndex,
        ) ||
        oldIndex < 0 ||
        oldIndex >= program.weeks[weekIndex].workouts[workoutIndex].exercises.length ||
        newIndex < 0 ||
        newIndex > program.weeks[weekIndex].workouts[workoutIndex].exercises.length) {
      throw ArgumentError('Indici di riordinamento non validi');
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final exercises = program.weeks[weekIndex].workouts[workoutIndex].exercises;
    final exercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, exercise);

    local_model_utils.ModelUtils.updateExerciseOrders(exercises, 0);
  }

  /// Sposta un esercizio da un workout a un altro
  void moveExercise(
    TrainingProgram program,
    int weekIndex,
    int sourceWorkoutIndex,
    int destinationWorkoutIndex,
    int exerciseIndex,
  ) {
    // Validazione degli indici
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      sourceWorkoutIndex,
      exerciseIndex,
    )) {
      throw ArgumentError('Indici di origine non validi per spostamento esercizio');
    }

    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      destinationWorkoutIndex,
    )) {
      throw ArgumentError('Indici di destinazione non validi per spostamento esercizio');
    }

    if (sourceWorkoutIndex == destinationWorkoutIndex) {
      throw ArgumentError('Il workout di origine e destinazione non possono essere uguali');
    }

    // Ottieni l'esercizio da spostare
    final exerciseToMove =
        program.weeks[weekIndex].workouts[sourceWorkoutIndex].exercises[exerciseIndex];

    // Rimuovi l'esercizio dal workout di origine
    program.weeks[weekIndex].workouts[sourceWorkoutIndex].exercises.removeAt(exerciseIndex);

    // Aggiorna gli ordini nel workout di origine
    final sourceExercises = program.weeks[weekIndex].workouts[sourceWorkoutIndex].exercises;
    local_model_utils.ModelUtils.updateExerciseOrders(sourceExercises, exerciseIndex);

    // Calcola il nuovo ordine per il workout di destinazione
    final destinationExercises =
        program.weeks[weekIndex].workouts[destinationWorkoutIndex].exercises;
    final newOrder = destinationExercises.length + 1;

    // Aggiorna l'ordine dell'esercizio
    final exerciseWithNewOrder = exerciseToMove.copyWith(order: newOrder);

    // Aggiungi l'esercizio al workout di destinazione
    destinationExercises.add(exerciseWithNewOrder);
  }

  /// Aggiunge una serie alla progressione di un esercizio
  void addSeriesToProgression(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!local_validation_utils.ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    )) {
      throw ArgumentError('Indici non validi per aggiunta serie');
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final newSeriesOrder = exercise.series.length + 1;

    final newSeries = Series(
      serieId: generateRandomId(16).toString(),
      exerciseId: exercise.exerciseId ?? '',
      reps: 0,
      sets: 1,
      intensity: '',
      rpe: '',
      weight: 0.0,
      order: newSeriesOrder,
      done: false,
      repsDone: 0,
      weightDone: 0.0,
    );

    // Immutabile: aggiorna la lista serie tramite copyWith
    final updated = List<Series>.from(exercise.series)..add(newSeries);
    final updatedExercise = exercise.copyWith(series: updated);
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
  }

  /// Valida tutti gli esercizi di un workout
  bool validateWorkoutExercises(List<Exercise> exercises) {
    // Controlla ordini sequenziali
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i].order != i + 1) {
        return false;
      }
    }

    // Valida ogni esercizio
    return exercises.every(local_validation_utils.ValidationUtils.isValidExercise);
  }

  /// Ottiene statistiche sugli esercizi per un workout
  Map<String, dynamic> getExerciseStatistics(List<Exercise> exercises) {
    int totalSeries = 0;
    final exerciseTypes = <String, int>{};
    final exerciseNames = <String, int>{};

    for (final exercise in exercises) {
      totalSeries += exercise.series.length;
      exerciseTypes[exercise.type] = (exerciseTypes[exercise.type] ?? 0) + 1;
      exerciseNames[exercise.name] = (exerciseNames[exercise.name] ?? 0) + 1;
    }

    return {
      'totalExercises': exercises.length,
      'totalSeries': totalSeries,
      'averageSeriesPerExercise': exercises.isNotEmpty ? totalSeries / exercises.length : 0,
      'exerciseTypeDistribution': exerciseTypes,
      'mostUsedExercises': exerciseNames,
    };
  }

  // Metodi privati helper

  void _trackExerciseForDeletion(TrainingProgram program, Exercise exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (var series in exercise.series) {
      _trackSeriesForDeletion(program, series);
    }
  }

  void _trackSeriesForDeletion(TrainingProgram program, Series series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
  }
}
