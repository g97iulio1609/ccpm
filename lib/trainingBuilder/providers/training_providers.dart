import 'package:alphanessone/Viewer/services/training_program_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/providers/providers.dart';

// Unified service provider
final trainingProgramServicesProvider = Provider<TrainingProgramServices>(
  (ref) => TrainingProgramServices(),
);

// TrainingProgram state provider
final trainingProgramStateProvider =
    StateNotifierProvider<TrainingProgramStateNotifier, TrainingProgram>((ref) {
      return TrainingProgramStateNotifier(TrainingProgram());
    });

class TrainingProgramStateNotifier extends StateNotifier<TrainingProgram> {
  TrainingProgramStateNotifier(super.initialProgram);

  void updateProgram(TrainingProgram program) {
    state = program;
  }
}

// Controller provider (StateNotifier)
final trainingProgramControllerProvider =
    StateNotifierProvider<TrainingProgramController, TrainingProgram>((ref) {
      final service = ref.watch(firestoreServiceProvider);
      final usersService = ref.watch(usersServiceProvider);
      final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
      final programStateNotifier = ref.watch(
        trainingProgramStateProvider.notifier,
      );
      final programState = ref.watch(trainingProgramStateProvider);
      return TrainingProgramController(
        service,
        usersService,
        exerciseRecordService,
        programStateNotifier,
        programState,
        ref,
      );
    });

// Helper providers for specific service methods
final fetchTrainingWeeksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      programId,
    ) async {
      final services = ref.watch(trainingProgramServicesProvider);
      return services.fetchTrainingWeeks(programId);
    });

final getWorkoutsProvider = StreamProvider.family<QuerySnapshot, String>((
  ref,
  weekId,
) {
  final services = ref.watch(trainingProgramServicesProvider);
  return services.getWorkouts(weekId);
});

final fetchExercisesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      workoutId,
    ) async {
      final services = ref.watch(trainingProgramServicesProvider);
      return services.fetchExercises(workoutId);
    });

// You can add more helper providers for other service methods as needed
