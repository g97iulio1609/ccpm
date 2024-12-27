import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../exercise_model.dart';
import '../exercises_services.dart';
import '../../providers/providers.dart';

class ExerciseListController
    extends StateNotifier<AsyncValue<List<ExerciseModel>>> {
  final ExercisesService _exercisesService;
  List<ExerciseModel> _allExercises = [];
  String _currentSearchText = '';
  List<String> _selectedMuscleGroups = [];
  String? _currentExerciseType;

  ExerciseListController(this._exercisesService)
      : super(const AsyncValue.loading()) {
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
    final filteredList = _allExercises
        .where((exercise) =>
            exercise.name
                .toLowerCase()
                .contains(_currentSearchText.toLowerCase()) &&
            (_selectedMuscleGroups.isEmpty ||
                _selectedMuscleGroups
                    .any((group) => exercise.muscleGroups.contains(group))) &&
            (_currentExerciseType == null ||
                exercise.type == _currentExerciseType))
        .toList();

    // Ordina gli esercizi mettendo prima quelli in attesa di approvazione
    filteredList.sort((a, b) {
      if (a.status == 'pending' && b.status != 'pending') {
        return -1;
      } else if (a.status != 'pending' && b.status == 'pending') {
        return 1;
      }
      return a.name
          .compareTo(b.name); // Ordine alfabetico come criterio secondario
    });

    state = AsyncValue.data(filteredList);
  }

  List<ExerciseModel> getCurrentExercises() {
    return state.value ?? [];
  }

  void updateFilters({
    String? searchText,
    List<String>? muscleGroups,
    String? exerciseType,
  }) {
    if (searchText != null) _currentSearchText = searchText;
    if (muscleGroups != null) _selectedMuscleGroups = muscleGroups;
    if (exerciseType != null) _currentExerciseType = exerciseType;
    _applyFilters();
  }

  void resetFilters() {
    _currentSearchText = '';
    _selectedMuscleGroups = [];
    _currentExerciseType = null;
    state = AsyncValue.data(_allExercises);
  }

  void deleteExercise(String id) {
    _exercisesService.deleteExercise(id);
  }
}

final exerciseListControllerProvider = StateNotifierProvider<
    ExerciseListController, AsyncValue<List<ExerciseModel>>>(
  (ref) => ExerciseListController(ref.watch(exercisesServiceProvider)),
);
