part of 'training_program_controller.dart';

extension WorkoutExtension on TrainingProgramController {
  void addWorkout(int weekIndex) {
    final newWorkout = Workout(
      order: _program.weeks[weekIndex].workouts.length + 1,
      exercises: [],
    );
    _program.weeks[weekIndex].workouts.add(newWorkout);
    notifyListeners();
  }

  void removeWorkout(int weekIndex, int workoutOrder) {
    final workoutIndex = workoutOrder - 1;
    final workout = _program.weeks[weekIndex].workouts[workoutIndex];
    _removeWorkoutAndRelatedData(workout);
    _program.weeks[weekIndex].workouts.removeAt(workoutIndex);
    _updateWorkoutOrders(weekIndex, workoutIndex);
    notifyListeners();
  }

  void _removeWorkoutAndRelatedData(Workout workout) {
    if (workout.id != null) {
      _program.trackToDeleteWorkouts.add(workout.id!);
    }
    workout.exercises.forEach(_removeExerciseAndRelatedData);
  }

  void reorderWorkouts(int weekIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final workout = _program.weeks[weekIndex].workouts.removeAt(oldIndex);
    _program.weeks[weekIndex].workouts.insert(newIndex, workout);
    _updateWorkoutOrders(weekIndex, newIndex);
    notifyListeners();
  }

  void _updateWorkoutOrders(int weekIndex, int startIndex) {
    for (int i = startIndex; i < _program.weeks[weekIndex].workouts.length; i++) {
      _program.weeks[weekIndex].workouts[i].order = i + 1;
    }
  }

  Future<void> copyWorkout(int sourceWeekIndex, int workoutIndex,
      BuildContext context) async {
    final destinationWeekIndex = await _showCopyWorkoutDialog(context);
    if (destinationWeekIndex != null) {
      final sourceWorkout =
          _program.weeks[sourceWeekIndex].workouts[workoutIndex];
      final copiedWorkout = _copyWorkout(sourceWorkout);

      if (destinationWeekIndex < _program.weeks.length) {
        final destinationWeek = _program.weeks[destinationWeekIndex];
        final existingWorkoutIndex = destinationWeek.workouts.indexWhere(
          (workout) => workout.order == sourceWorkout.order,
        );

        if (existingWorkoutIndex != -1) {
          final existingWorkout =
              destinationWeek.workouts[existingWorkoutIndex];
          if (existingWorkout.id != null) {
            _program.trackToDeleteWorkouts.add(existingWorkout.id!);
          }
          destinationWeek.workouts[existingWorkoutIndex] = copiedWorkout;
        } else {
          destinationWeek.workouts.add(copiedWorkout);
        }
      } else {
        while (_program.weeks.length <= destinationWeekIndex) {
          addWeek();
        }
        _program.weeks[destinationWeekIndex].workouts.add(copiedWorkout);
      }

      notifyListeners();
    }
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

  Future<int?> _showCopyWorkoutDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copy Workout'),
          content: DropdownButtonFormField<int>(
            value: null,
            items: List.generate(
              _program.weeks.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text('Week ${index + 1}'),
              ),
            ),
            onChanged: (value) {
              Navigator.pop(context, value);
            },
            decoration: const InputDecoration(
              labelText: 'Destination Week',
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