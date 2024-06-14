import 'package:hooks_riverpod/hooks_riverpod.dart';
import './models/training_model.dart';

final trainingProgramStateProvider = StateNotifierProvider<TrainingProgramStateNotifier, TrainingProgram>((ref) {
  return TrainingProgramStateNotifier(TrainingProgram());
});

class TrainingProgramStateNotifier extends StateNotifier<TrainingProgram> {
  TrainingProgramStateNotifier(super.initialProgram);

  void updateProgram(TrainingProgram program) {
    state = program;
  }
}