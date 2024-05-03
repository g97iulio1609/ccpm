// week_state_provider.dart
import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/Provider/training_program_state_provider.dart';

final weekStateProvider = StateNotifierProvider<WeekStateNotifier, List<Week>>((ref) {
  return WeekStateNotifier(ref);
});

class WeekStateNotifier extends StateNotifier<List<Week>> {
  final Ref _ref;

  WeekStateNotifier(this._ref) : super([]);

  void init(List<Week> initialWeeks) {
    state = initialWeeks;
  }

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
    _ref.read(trainingProgramStateProvider.notifier).updateWeeks(state);
  }

  void removeWeek(int index) {
    final week = state[index];
    _removeWeekAndRelatedData(week);
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
    _updateWeekNumbers(index);
  }

  void _removeWeekAndRelatedData(Week week) {
    // Rimuovi i dati correlati a week
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
