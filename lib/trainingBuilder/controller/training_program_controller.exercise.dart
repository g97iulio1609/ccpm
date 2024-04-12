part of 'training_program_controller.dart';


extension ExerciseExtension on TrainingProgramController {
  Future<void> addExercise(
      int weekIndex, int workoutIndex, BuildContext context) async {
    final exercise = await _showExerciseDialog(context, null);
    if (exercise != null) {
      exercise.id = null;
      exercise.order =
          _program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
      _program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
      notifyListeners();
    }
  }

  Future<Exercise?> _showExerciseDialog(
      BuildContext context, Exercise? exercise) async {
    return await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        usersService: _usersService,
        athleteId: _athleteIdController.text,
        exercise: exercise,
      ),
    );
  }


  Future<void> editExercise(int weekIndex, int workoutIndex, int exerciseIndex,
      BuildContext context) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedExercise = await _showExerciseDialog(context, exercise);
    if (updatedExercise != null) {
      updatedExercise.order = exercise.order;
      _program.weeks[weekIndex].workouts[workoutIndex]
          .exercises[exerciseIndex] = updatedExercise;
      await updateExercise(updatedExercise.exerciseId ?? '');
    }
  }

  void removeExercise(int weekIndex, int workoutIndex, int exerciseIndex) {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _removeExerciseAndRelatedData(exercise);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(exerciseIndex);
    _updateExerciseOrders(weekIndex, workoutIndex, exerciseIndex);
    notifyListeners();
  }

  void _removeExerciseAndRelatedData(Exercise exercise) {
    if (exercise.id != null) {
      _program.trackToDeleteExercises.add(exercise.id!);
    }
    exercise.series.forEach(_removeSeriesData);
  }

  Future<void> updateExercise(String exerciseId) async {
    await _onExerciseChanged(exerciseId);
    notifyListeners();
  }

  Exercise? _findExerciseById(String exerciseId) {
    for (final week in _program.weeks) {
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

  void _updateExerciseWeights(Exercise exercise, double newMaxWeight) {
    final exerciseType = exercise.type ?? '';
    _updateSeriesWeights(exercise.series, newMaxWeight, exerciseType);
    _updateWeekProgressionWeights(exercise.weekProgressions, newMaxWeight, exerciseType);
  }

  void _updateSeriesWeights(
      List<Series> series, double maxWeight, String exerciseType) {
    for (final item in series) {
      final intensity = double.tryParse(item.intensity) ?? 0;
      final calculatedWeight = calculateWeightFromIntensity(maxWeight, intensity);
      item.weight = roundWeight(calculatedWeight, exerciseType);
    }
  }

  void _updateWeekProgressionWeights(
      List<WeekProgression> progressions, double maxWeight, String exerciseType) {
    for (final item in progressions) {
      final intensity = double.tryParse(item.intensity) ?? 0;
      final calculatedWeight = calculateWeightFromIntensity(maxWeight, intensity);
      item.weight = roundWeight(calculatedWeight, exerciseType);
    }
  }

  void reorderExercises(
      int weekIndex, int workoutIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercise =
        _program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(oldIndex);
    _program.weeks[weekIndex].workouts[workoutIndex].exercises.insert(newIndex, exercise);
    _updateExerciseOrders(weekIndex, workoutIndex, newIndex);
    notifyListeners();
  }

  void _updateExerciseOrders(int weekIndex, int workoutIndex, int startIndex) {
    for (int i = startIndex;
        i < _program.weeks[weekIndex].workouts[workoutIndex].exercises.length;
        i++) {
      _program.weeks[weekIndex].workouts[workoutIndex].exercises[i].order =
          i + 1;
    }
  }

 Exercise _copyExercise(Exercise sourceExercise) {
    final copiedSeries = sourceExercise.series.map((series) => series.copyWith()).toList();

    return sourceExercise.copyWith(
      id: UniqueKey().toString(),
      exerciseId: sourceExercise.exerciseId,
      series: copiedSeries,
    );
  }

  Future<void> applyWeekProgressions(int exerciseIndex,
      List<WeekProgression> weekProgressions, BuildContext context) async {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];

      for (int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++) {
        final workout = week.workouts[workoutIndex];

        for (int currentExerciseIndex = 0;
            currentExerciseIndex < workout.exercises.length;
            currentExerciseIndex++) {
          final exercise = workout.exercises[currentExerciseIndex];

          if (currentExerciseIndex == exerciseIndex) {
            final progression = weekIndex < weekProgressions.length
                ? weekProgressions[weekIndex]
                : weekProgressions.last;

            await _updateOrCreateSeries(exercise, progression, weekIndex,
                workoutIndex, currentExerciseIndex, context);
            _updateWeekProgression(
                weekIndex, workoutIndex, currentExerciseIndex, progression);
          }
        }
      }
    }

    notifyListeners();
  }

  Future<void> _updateOrCreateSeries(
      Exercise exercise,
      WeekProgression progression,
      int weekIndex,
      int workoutIndex,
      int exerciseIndex,
      BuildContext context) async {
    final existingSeries = exercise.series
        .where((series) => series.order ~/ 100 == weekIndex)
        .toList();

    await _adjustSeriesCount(existingSeries, progression.sets, weekIndex,
        workoutIndex, exerciseIndex, context);

    for (int i = 0; i < progression.sets; i++) {
      final series = existingSeries[i];
      series.reps = progression.reps;
      series.intensity = progression.intensity;
      series.rpe = progression.rpe;
      series.weight = progression.weight;
    }

    notifyListeners();
  }

  Future<void> _adjustSeriesCount(
      List<Series> existingSeries,
      int newSeriesCount,
      int weekIndex,
      int workoutIndex,
      int exerciseIndex,
      BuildContext context) async {
    if (existingSeries.length < newSeriesCount) {
      for (int i = existingSeries.length; i < newSeriesCount; i++) {
        await addSeries(weekIndex, workoutIndex, exerciseIndex, context);
      }
    } else if (existingSeries.length > newSeriesCount) {
      for (int i = newSeriesCount; i < existingSeries.length; i++) {
        final seriesIndex = existingSeries[i].order % 100 - 1;
        removeSeries(weekIndex, workoutIndex, exerciseIndex, 0, seriesIndex);
      }
    }
  }

  void _updateWeekProgression(int weekIndex, int workoutIndex,
      int exerciseIndex, WeekProgression progression) {
    final exercise =
        _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    if (exercise.weekProgressions.length <= weekIndex) {
      exercise.weekProgressions.add(progression);
    } else {
      exercise.weekProgressions[weekIndex] = progression;
    }
  }

  Future<void> updateExerciseProgressions(Exercise exercise,
      List<WeekProgression> updatedProgressions, BuildContext context) async {
    for (int weekIndex = 0; weekIndex < _program.weeks.length; weekIndex++) {
      final week = _program.weeks[weekIndex];

      for (int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++) {
        final workout = week.workouts[workoutIndex];

        final exerciseIndex =
            workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (exerciseIndex != -1) {
          final currentExercise = workout.exercises[exerciseIndex];
          currentExercise.weekProgressions = updatedProgressions;

          final progression = weekIndex < updatedProgressions.length
              ? updatedProgressions[weekIndex]
              : updatedProgressions.last;

          currentExercise.series.clear();

          await Future.forEach<int>(
              List.generate(progression.sets, (index) => index), (index) async {
            await addSeriesToProgression(
                weekIndex, workoutIndex, exerciseIndex, context);
            final latestSeries = currentExercise.series[index];
            latestSeries.reps = progression.reps;
            latestSeries.intensity = progression.intensity;
            latestSeries.rpe = progression.rpe;
            latestSeries.weight = progression.weight;
          });
        }
      }
    }

    notifyListeners();
  }
}