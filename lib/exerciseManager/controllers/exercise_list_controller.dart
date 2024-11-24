import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../exercise_model.dart';
import '../exercises_services.dart';
import '../../providers/providers.dart';

class ExerciseListController extends StateNotifier<AsyncValue<List<ExerciseModel>>> {
  final ExercisesService _exercisesService;
  List<ExerciseModel> _allExercises = [];
  String _currentSearchText = '';
  String? _currentMuscleGroup;
  String? _currentExerciseType;
  
  ExerciseListController(this._exercisesService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _exercisesService.getExercises().listen(
      (exercises) {
        _allExercises = exercises;
        _applyFilters(); // Applica i filtri correnti
      },
      onError: (error) => state = AsyncValue.error(error, StackTrace.current),
    );
  }

  void _applyFilters() {
    final filteredList = _allExercises.where((exercise) =>
      exercise.name.toLowerCase().contains(_currentSearchText.toLowerCase()) &&
      (_currentMuscleGroup == null || exercise.muscleGroup == _currentMuscleGroup) &&
      (_currentExerciseType == null || exercise.type == _currentExerciseType)
    ).toList();

    state = AsyncValue.data(filteredList);
  }

  List<ExerciseModel> getCurrentExercises() {
    return state.value ?? [];
  }

  void updateFilters({
    String? searchText,
    String? muscleGroup,
    String? exerciseType,
  }) {
    if (searchText != null) _currentSearchText = searchText;
    if (muscleGroup != null) _currentMuscleGroup = muscleGroup;
    if (exerciseType != null) _currentExerciseType = exerciseType;
    _applyFilters();
  }

  void resetFilters() {
    _currentSearchText = '';
    _currentMuscleGroup = null;
    _currentExerciseType = null;
    state = AsyncValue.data(_allExercises);
  }

  void deleteExercise(String id) {
    _exercisesService.deleteExercise(id);
  }
}

final exerciseListControllerProvider = StateNotifierProvider<ExerciseListController, AsyncValue<List<ExerciseModel>>>(
  (ref) => ExerciseListController(ref.watch(exercisesServiceProvider)),
); 