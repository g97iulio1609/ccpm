import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_model.dart';
import '../services/training_program_services.dart';

// Unified service provider
final trainingProgramServicesProvider = Provider<TrainingProgramServices>((ref) => TrainingProgramServices());

// Timer providers
final timerModelProvider = StateProvider<TimerModel?>((ref) => null);
final remainingSecondsProvider = StateProvider<int>((ref) => 0);

// Training program providers
final trainingWeeksProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
final trainingLoadingProvider = StateProvider<bool>((ref) => false);

// Workout providers
final workoutIdProvider = StateProvider<String>((ref) => '');
final exercisesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
final loadingProvider = StateProvider<bool>((ref) => false);

// New provider for current workout name
final currentWorkoutNameProvider = StateProvider<String>((ref) => 'Allenamento');

// Helper providers for specific service methods
final fetchTrainingWeeksProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, programId) async {
  final services = ref.watch(trainingProgramServicesProvider);
  return services.fetchTrainingWeeks(programId);
});

final getWorkoutsProvider = StreamProvider.family<QuerySnapshot, String>((ref, weekId) {
  final services = ref.watch(trainingProgramServicesProvider);
  return services.getWorkouts(weekId);
});

final fetchExercisesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, workoutId) async {
  final services = ref.watch(trainingProgramServicesProvider);
  return services.fetchExercises(workoutId);
});

// Additional providers for other service methods can be added here as needed