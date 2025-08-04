import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/shared/shared.dart';
import 'series_service.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:intl/intl.dart';

class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SeriesService _seriesService = SeriesService();

  Future<String> addExerciseToWorkout(
      String workoutId, Map<String, dynamic> exerciseData) async {
    // Ensure exerciseData contains the exerciseId which will be used as originalExerciseId
    if (!exerciseData.containsKey('exerciseId')) {
      throw ArgumentError('exerciseId is required in exerciseData');
    }

    // Salviamo le serie separatamente
    List<Series>? series;
    if (exerciseData.containsKey('series')) {
      series = List<Series>.from(
          exerciseData['series']?.map((x) => Series.fromMap(x)) ?? []);
      exerciseData.remove('series');
    }

    DocumentReference ref = await _db.collection('exercisesWorkout').add({
      ...exerciseData,
      'workoutId': workoutId,
    });

    // Se ci sono serie, le salviamo con l'originalExerciseId corretto
    if (series != null) {
      for (var serie in series) {
        await _seriesService.addSeriesToExercise(
          ref.id,
          serie,
          originalExerciseId: exerciseData['exerciseId'],
        );
      }
    }

    return ref.id;
  }

  Future<void> updateExercise(
      String exerciseId, Map<String, dynamic> exerciseData) async {
    // Se ci sono serie da aggiornare
    if (exerciseData.containsKey('series')) {
      List<Series> series = List<Series>.from(
          exerciseData['series']?.map((x) => Series.fromMap(x)) ?? []);
      exerciseData.remove('series');

      // Aggiorniamo ogni serie con l'originalExerciseId corretto
      for (var serie in series) {
        if (serie.id != null) {
          await _seriesService.updateSeries(serie.id!,
              serie.copyWith(originalExerciseId: exerciseData['exerciseId']));
        } else {
          await _seriesService.addSeriesToExercise(
            exerciseId,
            serie,
            originalExerciseId: exerciseData['exerciseId'],
          );
        }
      }
    }

    await _db
        .collection('exercisesWorkout')
        .doc(exerciseId)
        .update(exerciseData);
  }

  Future<void> removeExercise(String exerciseId) async {
    await _db.collection('exercisesWorkout').doc(exerciseId).delete();
  }

  Future<List<Exercise>> fetchExercisesByWorkoutId(String workoutId) async {
    var snapshot = await _db
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .get();
    var exercises =
        snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
    return exercises;
  }

  /// Gets the latest max weight for an exercise
  static Future<num> getLatestMaxWeight(
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    String exerciseId,
  ) async {
    if (exerciseId.isEmpty) return 0;

    try {
      final record = await exerciseRecordService.getLatestExerciseRecord(
        userId: athleteId,
        exerciseId: exerciseId,
      );
      return record?.maxWeight ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Calculates and updates max RM for an exercise
  static Future<void> updateMaxRM({
    required ExerciseRecordService exerciseRecordService,
    required String athleteId,
    required Exercise exercise,
    required double maxWeight,
    required int repetitions,
    required String exerciseType,
  }) async {
    if (exercise.exerciseId == null) return;

    final dateFormat = DateFormat('yyyy-MM-dd');
    final roundedMaxWeight = roundWeight(maxWeight, exerciseType);

    try {
      final existingRecord =
          await exerciseRecordService.getLatestExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
      );

      if (existingRecord != null) {
        await exerciseRecordService.updateExerciseRecord(
          userId: athleteId,
          exerciseId: exercise.exerciseId!,
          recordId: existingRecord.id,
          maxWeight: roundedMaxWeight.round(),
          repetitions: 1,
        );
      } else {
        await exerciseRecordService.addExerciseRecord(
          userId: athleteId,
          exerciseId: exercise.exerciseId!,
          exerciseName: exercise.name,
          maxWeight: roundedMaxWeight.round(),
          repetitions: 1,
          date: dateFormat.format(DateTime.now()),
        );
      }
    } catch (e) {
      throw Exception('Failed to update max RM: $e');
    }
  }

  /// Calculates max RM from weight and repetitions
  static double calculateMaxRM(double weight, int repetitions) {
    if (repetitions <= 1) return weight;
    return weight / (1.0278 - (0.0278 * repetitions));
  }

  /// Creates bulk series for multiple exercises
  static List<Exercise> createBulkSeries({
    required List<Exercise> exercises,
    required int sets,
    required int reps,
    int? maxReps,
    String? intensity,
    String? maxIntensity,
    String? rpe,
    String? maxRpe,
    required Map<String, num> exerciseMaxWeights,
  }) {
    return exercises.map((exercise) {
      final maxWeight = exerciseMaxWeights[exercise.exerciseId] ?? 0;
      final calculatedWeight = _calculateWeightFromIntensity(
        maxWeight.toDouble(),
        double.tryParse(intensity ?? '') ?? 0,
      );
      final calculatedMaxWeight = maxIntensity != null
          ? _calculateWeightFromIntensity(
              maxWeight.toDouble(),
              double.tryParse(maxIntensity) ?? 0,
            )
          : null;

      final newSeries = List.generate(
        sets,
        (index) => Series(
          serieId: generateRandomId(16),
          exerciseId: exercise.exerciseId ?? '',
          reps: reps,
          maxReps: maxReps,
          sets: 1,
          intensity: intensity ?? '',
          maxIntensity: maxIntensity,
          rpe: rpe ?? '',
          maxRpe: maxRpe,
          weight: calculatedWeight,
          maxWeight: calculatedMaxWeight,
          order: index + 1,
          done: false,
          repsDone: 0,
          weightDone: 0,
        ),
      );

      return exercise.copyWith(series: newSeries);
    }).toList();
  }

  /// Calculates weight from intensity percentage
  static double _calculateWeightFromIntensity(
      double maxWeight, double intensity) {
    if (maxWeight <= 0 || intensity <= 0) return 0;
    return maxWeight * (intensity / 100);
  }

  /// Validates exercise data
  static bool isValidExercise(Exercise exercise) {
    return exercise.name.isNotEmpty && exercise.type.isNotEmpty;
  }

  /// Creates a copy of an exercise with new ID
  static Exercise copyExercise(Exercise original) {
    return Exercise(
      id: generateRandomId(16),
      name: original.name,
      type: original.type,
      variant: original.variant,
      order: original.order,
      exerciseId: original.exerciseId,
      series: original.series
          .map((s) => s.copyWith(
                serieId: generateRandomId(16),
              ))
          .toList(),
      weekProgressions: original.weekProgressions,
    );
  }

  /// Groups exercises by type for better organization
  static Map<String, List<Exercise>> groupExercisesByType(
      List<Exercise> exercises) {
    final groupedExercises = <String, List<Exercise>>{};

    for (var exercise in exercises) {
      if (!groupedExercises.containsKey(exercise.type)) {
        groupedExercises[exercise.type] = [];
      }
      groupedExercises[exercise.type]!.add(exercise);
    }

    return groupedExercises;
  }

  /// Calculates total volume for an exercise
  static double calculateExerciseVolume(Exercise exercise) {
    double totalVolume = 0;

    for (var series in exercise.series) {
      final reps = series.repsDone > 0 ? series.repsDone : series.reps;
      final weight =
          series.weightDone > 0 ? series.weightDone : series.weight;
      totalVolume += reps * weight;
    }

    return totalVolume;
  }
}
