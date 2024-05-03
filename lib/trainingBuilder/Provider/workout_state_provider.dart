import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:alphanessone/trainingBuilder/Provider/training_program_state_provider.dart';

final workoutStateProvider = StateNotifierProvider<WorkoutStateNotifier, List<Workout>>((ref) {
  return WorkoutStateNotifier(ref);
});

class WorkoutStateNotifier extends StateNotifier<List<Workout>> {
  final Ref _ref;

  WorkoutStateNotifier(this._ref) : super([]);

  void init(int weekIndex, List<Workout> initialWorkouts) {
    state = initialWorkouts;
  }

  void addWorkout(int weekIndex) {
    final newWorkout = Workout(
      id: null,
      order: state.length + 1,
      exercises: [],
    );

    state = [...state, newWorkout];
    _ref.read(trainingProgramStateProvider.notifier).updateWorkouts(weekIndex, state);
  }

  void removeWorkout(int index, TrainingProgram program, int weekIndex) {
    final workout = state[index];
    _removeWorkoutAndRelatedData(workout, program);
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
    _updateWorkoutOrders(index);
    _ref.read(trainingProgramStateProvider.notifier).updateWorkouts(weekIndex, state);
  }

  void _removeWorkoutAndRelatedData(Workout workout, TrainingProgram program) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    for (var exercise in workout.exercises) {
      _removeExerciseAndRelatedData(exercise, program);
    }
  }

  void _removeExerciseAndRelatedData(Exercise exercise, TrainingProgram program) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (var series in exercise.series) {
      _removeSeriesData(series, program);
    }
  }

  void _removeSeriesData(Series series, TrainingProgram program) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
  }

  void _updateWorkoutOrders(int startIndex) {
    for (int i = startIndex; i < state.length; i++) {
      state[i] = state[i].copyWith(order: i + 1);
    }
  }

  void reorderWorkouts(int oldIndex, int newIndex, int weekIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final workout = state.removeAt(oldIndex);
    state = [...state.sublist(0, newIndex), workout, ...state.sublist(newIndex)];
    _updateWorkoutOrders(newIndex);
    _ref.read(trainingProgramStateProvider.notifier).updateWorkouts(weekIndex, state);
  }

  Future<void> copyWorkout(int sourceIndex, BuildContext context, TrainingProgram program, int weekIndex) async {
    final destinationIndex = await _showCopyWorkoutDialog(context);
    if (destinationIndex != null) {
      final sourceWorkout = state[sourceIndex];
      final copiedWorkout = _copyWorkout(sourceWorkout, program);

      if (destinationIndex < state.length) {
        state[destinationIndex] = copiedWorkout;
      } else {
        copiedWorkout.order = state.length + 1;
        state = [...state, copiedWorkout];
      }
      _ref.read(trainingProgramStateProvider.notifier).updateWorkouts(weekIndex, state);
    }
  }

  Workout _copyWorkout(Workout sourceWorkout, TrainingProgram program) {
    final copiedExercises = sourceWorkout.exercises
        .map((exercise) => _copyExercise(exercise, program))
        .toList();

    return Workout(
      id: null,
      order: sourceWorkout.order,
      exercises: copiedExercises,
    );
  }

  Exercise _copyExercise(Exercise sourceExercise, TrainingProgram program) {
    final copiedSeries = sourceExercise.series.map((series) => _copySeries(series, program)).toList();

    return sourceExercise.copyWith(
      id: generateRandomId(16).toString(),
      exerciseId: sourceExercise.exerciseId,
      series: copiedSeries,
    );
  }

  Series _copySeries(Series sourceSeries, TrainingProgram program) {
    return sourceSeries.copyWith(
      serieId: generateRandomId(16).toString(),
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
  }

  Future<int?> _showCopyWorkoutDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copy Workout'),
          content: DropdownButtonFormField<int>(
            value: null,
            items: List.generate(
              state.length + 1,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(index < state.length
                    ? 'Workout ${state[index].order}'
                    : 'New Workout'),
              ),
            ),
            onChanged: (value) {
              Navigator.pop(context, value);
            },
            decoration: const InputDecoration(
              labelText: 'Destination Workout',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}