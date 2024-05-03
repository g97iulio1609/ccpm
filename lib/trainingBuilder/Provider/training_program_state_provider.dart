import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/training_model.dart';

final trainingProgramStateProvider =
    StateNotifierProvider<TrainingProgramStateNotifier, TrainingProgram>((ref) {
  return TrainingProgramStateNotifier();
});

class TrainingProgramStateNotifier extends StateNotifier<TrainingProgram> {
  TrainingProgramStateNotifier() : super(TrainingProgram());

  void updateProgram(TrainingProgram program) {
    state = program;
  }

  void updateWeeks(List<Week> weeks) {
    state = state.copyWith(weeks: weeks);
  }

  void updateWorkouts(int weekIndex, List<Workout> workouts) {
    final updatedWeeks = state.weeks.toList();
    updatedWeeks[weekIndex] = updatedWeeks[weekIndex].copyWith(workouts: workouts);
    state = state.copyWith(weeks: updatedWeeks);
  }
}