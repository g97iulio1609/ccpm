import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';

final weekStateProvider = StateNotifierProvider<WeekStateNotifier, List<Week>>((ref) {
  return WeekStateNotifier(ref);
});

class WeekStateNotifier extends StateNotifier<List<Week>> {
  final Ref _ref;
  final List<String> _trackToDeleteWeeks = [];
  final List<String> _trackToDeleteWorkouts = [];
  final List<String> _trackToDeleteExercises = [];
  final List<String> _trackToDeleteSeries = [];

  WeekStateNotifier(this._ref) : super([]);

  void addWeek() {
    final newWeek = Week(
      id: null,
      number: state.length + 1,
      workouts: [
        Workout(
          id: '',
          order: 1,
          exercises: [],
        ),
      ],
    );

    state = [...state, newWeek];
  }

  void removeWeek(int index) {
    final week = state[index];
    _removeWeekAndRelatedData(week);
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
    _updateWeekNumbers(index);
  }

  void _removeWeekAndRelatedData(Week week) {
    if (week.id != null) {
      _trackToDeleteWeeks.add(week.id!);
    }
    for (var workout in week.workouts) {
      _removeWorkoutAndRelatedData(workout);
    }
  }

  void _removeWorkoutAndRelatedData(Workout workout) {
    if (workout.id != null) {
      _trackToDeleteWorkouts.add(workout.id!);
    }
    for (var exercise in workout.exercises) {
      _removeExerciseAndRelatedData(exercise);
    }
  }

  void _removeExerciseAndRelatedData(Exercise exercise) {
    if (exercise.id != null) {
      _trackToDeleteExercises.add(exercise.id!);
    }
    for (var series in exercise.series) {
      _removeSeriesData(series);
    }
  }

  void _removeSeriesData(Series series) {
    if (series.serieId != null) {
      _trackToDeleteSeries.add(series.serieId!);
    }
  }

  void _updateWeekNumbers(int startIndex) {
    for (int i = startIndex; i < state.length; i++) {
      state[i] = state[i].copyWith(number: i + 1);
    }
  }

  void reorderWeeks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final week = state.removeAt(oldIndex);
    state = [...state.sublist(0, newIndex), week, ...state.sublist(newIndex)];
    _updateWeekNumbers(newIndex);
  }

  Future<void> copyWeek(int sourceWeekIndex, BuildContext context) async {
    final destinationWeekIndex = await _showCopyWeekDialog(context);
    if (destinationWeekIndex != null) {
      final sourceWeek = state[sourceWeekIndex];
      final copiedWeek = _copyWeek(sourceWeek);

      if (destinationWeekIndex < state.length) {
        final destinationWeek = state[destinationWeekIndex];
        _trackToDeleteWeeks.add(destinationWeek.id!);
        state[destinationWeekIndex] = copiedWeek;
      } else {
        copiedWeek.number = state.length + 1;
        state = [...state, copiedWeek];
      }
    }
  }

  Week _copyWeek(Week sourceWeek) {
    final copiedWorkouts =
        sourceWeek.workouts.map((workout) => _copyWorkout(workout)).toList();

    return Week(
      id: null,
      number: sourceWeek.number,
      workouts: copiedWorkouts,
    );
  }

  Workout _copyWorkout(Workout sourceWorkout) {
    final copiedExercises = sourceWorkout.exercises
        .map((exercise) => _copyExercise(exercise))
        .toList();

    return Workout(
      id: null,
      order: sourceWorkout.order,
      exercises: copiedExercises,
    );
  }

  Exercise _copyExercise(Exercise sourceExercise) {
    final copiedSeries =
        sourceExercise.series.map((series) => _copySeries(series)).toList();

    return sourceExercise.copyWith(
      id: generateRandomId(16).toString(),
      exerciseId: sourceExercise.exerciseId,
      series: copiedSeries,
    );
  }

  Series _copySeries(Series sourceSeries) {
    return sourceSeries.copyWith(
      serieId: generateRandomId(16).toString(),
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
  }

  Future<int?> _showCopyWeekDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copia Settimana'),
          content: DropdownButtonFormField<int>(
            value: null,
            items: List.generate(
              state.length + 1,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(index < state.length
                    ? 'Settimana ${state[index].number}'
                    : 'Nuova Settimana'),
              ),
            ),
            onChanged: (value) {
              Navigator.pop(context, value);
            },
            decoration: const InputDecoration(
              labelText: 'Settimana di destinazione',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }
}