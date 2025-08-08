import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Viewer/UI/workout_provider.dart'
    as workout_provider;

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class WorkoutFormatters {
  static dynamic formatSeriesValue(
    Map<String, dynamic> seriesData,
    String field,
    WidgetRef ref,
  ) {
    final value = seriesData[field];
    final maxValue = seriesData['max${field.capitalize()}'];
    final valueDone = seriesData['${field}_done'];
    final isDone = ref
        .read(workout_provider.workoutServiceProvider)
        .isSeriesDone(seriesData);
    final unit = field == 'reps' ? 'R' : 'Kg';

    // Se non ci sono valori done o sono zero, mostra solo i target
    if (valueDone == null || valueDone == 0) {
      return maxValue != null && maxValue != value
          ? '$value-$maxValue$unit'
          : '$value$unit';
    }

    // Se la serie è completata, mostra solo il valore done
    if (isDone) {
      return '$valueDone$unit';
    }

    // Se la serie è fallita, prepara sia il formato esteso che quello compatto
    final targetText = maxValue != null && maxValue != value
        ? '$value-$maxValue'
        : '$value';

    return {
      'compact': '$valueDone$unit',
      'extended': '$valueDone/$targetText$unit',
    };
  }

  static String formatSeriesValueForMobile(
    Map<String, dynamic> seriesData,
    String field,
    WidgetRef ref,
  ) {
    final value = seriesData[field];
    final maxValue = seriesData['max${field.capitalize()}'];
    final valueDone = seriesData['${field}_done'];
    final isDone = ref
        .read(workout_provider.workoutServiceProvider)
        .isSeriesDone(seriesData);
    final unit = field == 'reps' ? 'R' : 'Kg';

    if (valueDone == null || valueDone == 0) {
      return maxValue != null && maxValue != value
          ? '$value-$maxValue$unit'
          : '$value$unit';
    }

    if (isDone) {
      return '$valueDone$unit';
    }

    // Su mobile mostra solo il valore compatto per risparmiare spazio
    return '$valueDone$unit';
  }

  static bool determineSeriesStatus(
    Map<String, dynamic> seriesData,
    WidgetRef ref,
  ) {
    return ref
        .read(workout_provider.workoutServiceProvider)
        .isSeriesDone(seriesData);
  }

  static bool isSeriesFailed(Map<String, dynamic> seriesData) {
    final repsDone = seriesData['reps_done'];
    final weightDone = seriesData['weight_done'];
    final targetReps = seriesData['reps'];
    final targetWeight = seriesData['weight'];

    // Verifica se l'utente ha tentato la serie
    if ((repsDone != null && repsDone != 0) ||
        (weightDone != null && weightDone != 0)) {
      // Verifica se ha fallito (valori inferiori al target)
      if ((repsDone != null && repsDone < targetReps) ||
          (weightDone != null && weightDone < targetWeight)) {
        return true;
      }
    }
    return false;
  }

  static bool hasAttemptedSeries(Map<String, dynamic> seriesData) {
    final repsDone = seriesData['reps_done'];
    final weightDone = seriesData['weight_done'];
    return (repsDone != null && repsDone != 0) ||
        (weightDone != null && weightDone != 0);
  }

  // Shared formatting utilities to eliminate duplication
  static String formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String formatWeight(dynamic weight) {
    if (weight == null) return '-';
    if (weight is int || weight is double) {
      final num w = weight as num;
      final str = (w % 1 == 0) ? w.toInt().toString() : w.toStringAsFixed(1);
      return '$str kg';
    }
    return '$weight kg';
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    }
    return '${remainingSeconds}s';
  }

  static String formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m${secs > 0 ? ' ${secs}s' : ''}';
    }
    return '${secs}s';
  }
}
