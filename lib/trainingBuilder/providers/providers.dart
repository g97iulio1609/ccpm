import 'package:alphanessone/Viewer/services/week_services.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';
import 'package:alphanessone/trainingBuilder/services/series_service.dart';
import 'package:alphanessone/trainingBuilder/services/training_services.dart';
import 'package:alphanessone/trainingBuilder/services/workout_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Providers for each service
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});


final trainingProgramStateProvider = StateNotifierProvider<TrainingProgramStateNotifier, TrainingProgram>((ref) {
  return TrainingProgramStateNotifier(TrainingProgram());
});

class TrainingProgramStateNotifier extends StateNotifier<TrainingProgram> {
  TrainingProgramStateNotifier(super.initialProgram);

  void updateProgram(TrainingProgram program) {
    state = program;
  }
}

final weekServiceProvider = Provider<WeekService>((ref) {
  return WeekService();
});

final workoutServiceProvider = Provider<TrainingWorkoutService>((ref) {
  return TrainingWorkoutService();
});

final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  return ExerciseService();
});

final seriesServiceProvider = Provider<SeriesService>((ref) {
  return SeriesService();
});