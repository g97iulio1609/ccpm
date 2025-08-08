import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/range_controllers.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart' as tb_format;

/// Controller per tutti i campi di una serie
class SeriesControllers {
  final RangeControllers reps;
  final TextEditingController sets;
  final RangeControllers intensity;
  final RangeControllers rpe;
  final RangeControllers weight;

  SeriesControllers()
    : reps = RangeControllers(),
      sets = TextEditingController(text: '1'),
      intensity = RangeControllers(),
      rpe = RangeControllers(),
      weight = RangeControllers();

  void dispose() {
    reps.dispose();
    sets.dispose();
    intensity.dispose();
    rpe.dispose();
    weight.dispose();
  }

  void initializeFromSeries(Series series) {
    reps.min.text = tb_format.FormatUtils.formatNumber(series.reps.toString());
    reps.max.text = tb_format.FormatUtils.formatNumber(series.maxReps?.toString() ?? '');
    sets.text = tb_format.FormatUtils.formatNumber(series.sets.toString());
    intensity.min.text = tb_format.FormatUtils.formatNumber(series.intensity ?? '');
    intensity.max.text = tb_format.FormatUtils.formatNumber(series.maxIntensity ?? '');
    rpe.min.text = tb_format.FormatUtils.formatNumber(series.rpe ?? '');
    rpe.max.text = tb_format.FormatUtils.formatNumber(series.maxRpe ?? '');
    weight.min.text = tb_format.FormatUtils.formatNumber(series.weight.toString());
    weight.max.text = tb_format.FormatUtils.formatNumber(series.maxWeight?.toString() ?? '');
  }


  void clear() {
    reps.clear();
    sets.text = '1';
    intensity.clear();
    rpe.clear();
    weight.clear();
  }

  bool get isValid {
    final setsValue = int.tryParse(sets.text) ?? 0;
    final repsValue = int.tryParse(reps.min.text) ?? 0;
    return setsValue > 0 && repsValue > 0;
  }
}

/// Notifier per gestire lo stato dei controller delle serie bulk
class BulkSeriesControllersNotifier
    extends StateNotifier<List<SeriesControllers>> {
  BulkSeriesControllersNotifier() : super([]);

  void initialize(List<Exercise> exercises) {
    // Disponi dei controller esistenti prima di crearne di nuovi
    for (final controller in state) {
      controller.dispose();
    }
    state = exercises.map((_) => SeriesControllers()).toList();
  }

  void updateControllers(int index, Series series) {
    if (index >= 0 && index < state.length) {
      state[index].initializeFromSeries(series);
      state = [...state];
    }
  }

  void addControllers() {
    state = [...state, SeriesControllers()];
  }

  void removeControllers(int index) {
    if (index >= 0 && index < state.length) {
      final newState = List<SeriesControllers>.from(state);
      final removedController = newState.removeAt(index);
      removedController.dispose();
      state = newState;
    }
  }

  void updateControllersForExercises(List<Exercise> exercises) {
    final newState = List<SeriesControllers>.from(state);
    for (int i = 0; i < exercises.length && i < state.length; i++) {
      if (exercises[i].series.isNotEmpty) {
        newState[i].initializeFromSeries(exercises[i].series.first);
      }
    }
    state = newState;
  }

  void clearAll() {
    for (final controller in state) {
      controller.dispose();
    }
    state = [];
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}

/// Provider per i controller delle serie bulk
final bulkSeriesControllersProvider =
    StateNotifierProvider<
      BulkSeriesControllersNotifier,
      List<SeriesControllers>
    >((ref) {
      return BulkSeriesControllersNotifier();
    });
