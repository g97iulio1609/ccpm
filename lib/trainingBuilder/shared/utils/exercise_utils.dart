import '../../../shared/shared.dart';
import '../../../ExerciseRecords/exercise_record_services.dart';
import './format_utils.dart' as training_builder_format_utils;

/// Utility class per operazioni sugli esercizi
class ExerciseUtils {
  /// Ottiene i SuperSet associati a un esercizio
  static List<SuperSet> getSuperSets(
    Exercise exercise,
    List<SuperSet> allSuperSets,
  ) {
    return allSuperSets
        .where((superSet) => superSet.exerciseIds.contains(exercise.id))
        .toList();
  }

  /// Verifica se un esercizio è parte di un SuperSet
  static bool isInSuperSet(Exercise exercise, List<SuperSet> superSets) {
    return getSuperSets(exercise, superSets).isNotEmpty;
  }

  /// Ottiene il primo SuperSet associato a un esercizio
  static SuperSet? getFirstSuperSet(
    Exercise exercise,
    List<SuperSet> superSets,
  ) {
    final exerciseSuperSets = getSuperSets(exercise, superSets);
    return exerciseSuperSets.isNotEmpty ? exerciseSuperSets.first : null;
  }

  /// Calcola il Max RM usando la formula di Brzycki
  static double calculateMaxRM(double weight, int repetitions) {
    if (repetitions == 1) return weight;
    if (repetitions <= 0 || weight <= 0) return 0;

    // Formula di Brzycki: 1RM = peso / (1.0278 - 0.0278 × ripetizioni)
    return weight / (1.0278 - 0.0278 * repetitions);
  }

  /// Ottiene il peso massimo registrato per un esercizio
  static Future<num> getLatestMaxWeight(
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    String exerciseId,
  ) async {
    if (exerciseId.isEmpty || athleteId.isEmpty) return 0;

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

  /// Aggiorna il Max RM per un esercizio
  static Future<void> updateMaxRM({
    required ExerciseRecordService exerciseRecordService,
    required String athleteId,
    required Exercise exercise,
    required double maxWeight,
    required int repetitions,
    required String exerciseType,
  }) async {
    if (exercise.exerciseId == null || exercise.exerciseId!.isEmpty) {
      throw Exception('Exercise ID non valido');
    }

    // Calcola il Max RM se necessario
    final calculatedMaxWeight = repetitions > 1
        ? calculateMaxRM(maxWeight, repetitions)
        : maxWeight;

    // Crea un nuovo record usando il metodo del servizio
    await exerciseRecordService.addExerciseRecord(
      userId: athleteId,
      exerciseId: exercise.exerciseId!,
      exerciseName: exercise.name,
      maxWeight: calculatedMaxWeight,
      repetitions: repetitions,
      date: DateTime.now().toIso8601String(),
    );
  }

  /// Formatta i nomi degli esercizi per la visualizzazione
  static List<String> formatExerciseNames(List<Exercise> exercises) {
    return exercises
        .map(
          (exercise) =>
              '${exercise.order}. ${exercise.name}${exercise.variant?.isNotEmpty == true ? ' (${exercise.variant})' : ''}',
        )
        .toList();
  }

  /// Verifica se un esercizio ha serie valide
  static bool hasValidSeries(Exercise exercise) {
    return exercise.series.isNotEmpty;
  }

  /// Ottiene il numero totale di serie per un esercizio
  static int getTotalSets(Exercise exercise) {
    return exercise.series.fold(0, (total, series) => total + series.sets);
  }

  /// Ottiene il range di ripetizioni per un esercizio
  static String getRepsRange(Exercise exercise) {
    if (exercise.series.isEmpty) return '';

    final minReps = exercise.series
        .map((s) => s.reps)
        .reduce((a, b) => a < b ? a : b);
    final maxReps = exercise.series
        .map((s) => s.maxReps ?? s.reps)
        .reduce((a, b) => a > b ? a : b);

    return minReps == maxReps
        ? training_builder_format_utils.FormatUtils.formatNumber(minReps)
        : '${training_builder_format_utils.FormatUtils.formatNumber(minReps)}-${training_builder_format_utils.FormatUtils.formatNumber(maxReps)}';
  }

  /// Ottiene il range di intensità per un esercizio
  static String getIntensityRange(Exercise exercise) {
    if (exercise.series.isEmpty) return '';

    final intensities = exercise.series
        .where((s) => s.intensity != null && s.intensity!.isNotEmpty)
        .map((s) => double.tryParse(s.intensity!) ?? 0)
        .where((i) => i > 0)
        .toList();

    if (intensities.isEmpty) return '';

    final minIntensity = intensities.reduce((a, b) => a < b ? a : b);
    final maxIntensity = intensities.reduce((a, b) => a > b ? a : b);

    return minIntensity == maxIntensity
        ? '${training_builder_format_utils.FormatUtils.formatNumber(minIntensity)}%'
        : '${training_builder_format_utils.FormatUtils.formatNumber(minIntensity)}-${training_builder_format_utils.FormatUtils.formatNumber(maxIntensity)}%';
  }

  /// Ottiene il range di peso per un esercizio
  static String getWeightRange(Exercise exercise) {
    if (exercise.series.isEmpty) return '';

    final weights = exercise.series
        .where((s) => s.weight > 0)
        .map((s) => s.weight)
        .toList();

    if (weights.isEmpty) return '';

    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    return minWeight == maxWeight
        ? '${training_builder_format_utils.FormatUtils.formatNumber(minWeight)} kg'
        : '${training_builder_format_utils.FormatUtils.formatNumber(minWeight)}-${training_builder_format_utils.FormatUtils.formatNumber(maxWeight)} kg';
  }

  /// Clona un esercizio per la duplicazione
  static Exercise cloneExercise(Exercise exercise, String newId, int newOrder) {
    return Exercise(
      id: newId,
      exerciseId: exercise.exerciseId,
      name: exercise.name,
      variant: exercise.variant,
      type: exercise.type,
      series: exercise.series.map((series) => series.copyWith()).toList(),
      order: newOrder,
    );
  }

  /// Valida i dati di un esercizio
  static bool isValidExercise(Exercise exercise) {
    return exercise.name.isNotEmpty &&
        exercise.type.isNotEmpty &&
        exercise.order > 0;
  }

  /// Ottiene un riepilogo testuale dell'esercizio
  static String getExerciseSummary(Exercise exercise) {
    final parts = <String>[];

    // Nome base
    parts.add(exercise.name);

    // Variante se presente
    if (exercise.variant?.isNotEmpty == true) {
      parts.add('(${exercise.variant})');
    }

    // Informazioni serie
    if (exercise.series.isNotEmpty) {
      final totalSets = getTotalSets(exercise);
      final repsRange = getRepsRange(exercise);
      if (totalSets > 0 && repsRange.isNotEmpty) {
        parts.add('$totalSets × $repsRange');
      }
    }

    return parts.join(' ');
  }

  /// Ordina gli esercizi per ordine
  static List<Exercise> sortExercisesByOrder(List<Exercise> exercises) {
    final sortedList = List<Exercise>.from(exercises);
    sortedList.sort((a, b) => a.order.compareTo(b.order));
    return sortedList;
  }

  /// Riordina gli esercizi aggiornando il campo order
  static List<Exercise> reorderExercises(
    List<Exercise> exercises,
    int oldIndex,
    int newIndex,
  ) {
    final reorderedList = List<Exercise>.from(exercises);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final exercise = reorderedList.removeAt(oldIndex);
    reorderedList.insert(newIndex, exercise);

    // Aggiorna gli ordini
    for (int i = 0; i < reorderedList.length; i++) {
      reorderedList[i] = reorderedList[i].copyWith(order: i + 1);
    }

    return reorderedList;
  }
}
