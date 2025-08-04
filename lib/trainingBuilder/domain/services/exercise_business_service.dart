import '../../models/training_model.dart';
import 'package:alphanessone/shared/shared.dart';
import '../../models/progressions_model.dart';
import '../repositories/training_repository.dart';
import '../../../ExerciseRecords/exercise_record_services.dart';
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/model_utils.dart';
import '../../utility_functions.dart';

/// Business service per le operazioni sugli esercizi
/// Segue il principio Single Responsibility
class ExerciseBusinessService {
  final ExerciseRepository _exerciseRepository;
  final SeriesRepository _seriesRepository;
  final ExerciseRecordService _exerciseRecordService;

  ExerciseBusinessService({
    required ExerciseRepository exerciseRepository,
    required SeriesRepository seriesRepository,
    required ExerciseRecordService exerciseRecordService,
  })  : _exerciseRepository = exerciseRepository,
        _seriesRepository = seriesRepository,
        _exerciseRecordService = exerciseRecordService;

  // Getter pubblico per permettere l'accesso dall'esterno
  ExerciseRecordService get exerciseRecordService => _exerciseRecordService;

  /// Aggiunge un esercizio al workout
  Future<void> addExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    Exercise exercise,
  ) async {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex)) {
      throw ArgumentError('Indici non validi per aggiunta esercizio');
    }

    if (!ValidationUtils.isValidExercise(exercise)) {
      throw ArgumentError('Dati esercizio non validi');
    }

    exercise.id = null;
    exercise.order =
        program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
    exercise.weekProgressions = List.generate(program.weeks.length, (_) => []);

    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);

    if (exercise.exerciseId != null) {
      await updateExerciseWeights(program, exercise.exerciseId!, exercise.type);
    }
  }

  /// Rimuove un esercizio dal workout
  void removeExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex, exerciseIndex)) {
      throw ArgumentError('Indici non validi per rimozione esercizio');
    }

    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _trackExerciseForDeletion(program, exercise);

    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(exerciseIndex);

    final exercises = program.weeks[weekIndex].workouts[workoutIndex].exercises;
    ModelUtils.updateExerciseOrders(exercises, exerciseIndex);
  }

  /// Duplica un esercizio nel workout
  void duplicateExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex, exerciseIndex)) {
      throw ArgumentError('Indici non validi per duplicazione esercizio');
    }

    final sourceExercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final duplicatedExercise = ModelUtils.copyExercise(sourceExercise);

    duplicatedExercise.order =
        program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .add(duplicatedExercise);
  }

  /// Aggiorna un esercizio esistente
  Future<void> updateExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    Exercise updatedExercise,
  ) async {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex, exerciseIndex)) {
      throw ArgumentError('Indici non validi per aggiornamento esercizio');
    }

    if (!ValidationUtils.isValidExercise(updatedExercise)) {
      throw ArgumentError('Dati esercizio aggiornato non validi');
    }

    final originalExercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    updatedExercise.order = originalExercise.order;
    updatedExercise.weekProgressions = originalExercise.weekProgressions;

    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] =
        updatedExercise;

    if (updatedExercise.exerciseId != null) {
      await updateExerciseWeights(
          program, updatedExercise.exerciseId!, updatedExercise.type);
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
      final newMaxWeight =
          await _getLatestMaxWeight(program.athleteId, exerciseId);

      for (final week in program.weeks) {
        for (final workout in week.workouts) {
          for (final exercise in workout.exercises) {
            if (exercise.exerciseId == exerciseId) {
              _updateExerciseWeightsInternal(
                  exercise, newMaxWeight.toDouble(), exerciseType);
            }
          }
        }
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking the flow
      print('Errore aggiornamento pesi per esercizio $exerciseId: $e');
    }
  }

  /// Aggiorna i pesi per un singolo esercizio del programma
  Future<void> updateSingleProgramExercise(
    TrainingProgram program,
    String exerciseId,
    String exerciseType,
  ) async {
    final exercise = _findExerciseById(program, exerciseId);
    if (exercise != null) {
      final newMaxWeight =
          await _getLatestMaxWeight(program.athleteId, exerciseId);
      _updateExerciseWeightsInternal(
          exercise, newMaxWeight.toDouble(), exerciseType);
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
    if (!ValidationUtils.isValidProgramIndex(
            program, weekIndex, workoutIndex) ||
        oldIndex < 0 ||
        oldIndex >=
            program.weeks[weekIndex].workouts[workoutIndex].exercises.length ||
        newIndex < 0 ||
        newIndex >
            program.weeks[weekIndex].workouts[workoutIndex].exercises.length) {
      throw ArgumentError('Indici di riordinamento non validi');
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final exercises = program.weeks[weekIndex].workouts[workoutIndex].exercises;
    final exercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, exercise);

    ModelUtils.updateExerciseOrders(exercises, 0);
  }

  /// Aggiunge una serie alla progressione di un esercizio
  void addSeriesToProgression(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex, exerciseIndex)) {
      throw ArgumentError('Indici non validi per aggiunta serie');
    }

    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final newSeriesOrder = exercise.series.length + 1;

    final newSeries = Series(
      serieId: generateRandomId(16).toString(),
      reps: 0,
      sets: 1,
      intensity: '',
      rpe: '',
      weight: 0.0,
      order: newSeriesOrder,
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );

    exercise.series.add(newSeries);
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
    return exercises.every(ValidationUtils.isValidExercise);
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
      'averageSeriesPerExercise':
          exercises.isNotEmpty ? totalSeries / exercises.length : 0,
      'exerciseTypeDistribution': exerciseTypes,
      'mostUsedExercises': exerciseNames,
    };
  }

  // Metodi privati helper

  Future<num> _getLatestMaxWeight(String athleteId, String exerciseId) async {
    if (exerciseId.isEmpty || athleteId.isEmpty) return 0;

    try {
      final record = await _exerciseRecordService.getLatestExerciseRecord(
        userId: athleteId,
        exerciseId: exerciseId,
      );
      return record?.maxWeight ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Exercise? _findExerciseById(TrainingProgram program, String exerciseId) {
    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.exerciseId == exerciseId) {
            return exercise;
          }
        }
      }
    }
    return null;
  }

  void _updateExerciseWeightsInternal(
      Exercise exercise, double maxWeight, String exerciseType) {
    // Aggiorna pesi delle serie
    _updateSeriesWeights(exercise.series, maxWeight, exerciseType);

    // Aggiorna pesi delle progressioni settimanali
    if (exercise.weekProgressions.isNotEmpty) {
      _updateWeekProgressionWeights(
          exercise.weekProgressions, maxWeight, exerciseType);
    }
  }

  void _updateSeriesWeights(
      List<Series> series, double maxWeight, String exerciseType) {
    for (int i = 0; i < series.length; i++) {
      final s = series[i];
      final intensity =
          s.intensity.isNotEmpty ? double.tryParse(s.intensity) : null;
      if (intensity != null) {
        final calculatedWeight =
            calculateWeightFromIntensity(maxWeight, intensity);
        series[i] = s.copyWith(weight: roundWeight(calculatedWeight, exerciseType));
      }
    }
  }

  void _updateWeekProgressionWeights(
    List<List<WeekProgression>> progressions,
    double maxWeight,
    String exerciseType,
  ) {
    for (final weekProgressions in progressions) {
      for (final progression in weekProgressions) {
        for (int i = 0; i < progression.series.length; i++) {
          final series = progression.series[i];
          final intensity = series.intensity.isNotEmpty
              ? double.tryParse(series.intensity)
              : null;

          if (intensity != null) {
            final calculatedWeight =
                calculateWeightFromIntensity(maxWeight, intensity);
            progression.series[i] = series.copyWith(
              weight: roundWeight(calculatedWeight, exerciseType),
            );
          }
        }
      }
    }
  }

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
