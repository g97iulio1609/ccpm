// providers.dart
import 'package:alphanessone/measurements/measurements_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/users_services.dart';
import '../services/tdee_services.dart';
import '../ExerciseRecords/exercise_record_services.dart';
import '../measurements/measurements_services.dart';
import '../exerciseManager/exercises_services.dart';
import '../exerciseManager/exercise_model.dart';
import '../Coaching/coaching_service.dart';
import '../models/measurement_model.dart';
import '../models/user_model.dart';

// Firebase-related providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Service providers
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, ref.watch(firebaseFirestoreProvider), ref.watch(firebaseAuthProvider));
});

final tdeeServiceProvider = Provider<TDEEService>((ref) => TDEEService(ref.watch(firebaseFirestoreProvider)));
final exerciseRecordServiceProvider = Provider<ExerciseRecordService>((ref) => ExerciseRecordService(ref.watch(firebaseFirestoreProvider)));
final measurementsServiceProvider = Provider<MeasurementsService>((ref) => MeasurementsService(ref.watch(firebaseFirestoreProvider)));
final exercisesServiceProvider = Provider<ExercisesService>((ref) => ExercisesService(ref.watch(firebaseFirestoreProvider)));
final coachingServiceProvider = Provider<CoachingService>((ref) => CoachingService(ref.watch(firebaseFirestoreProvider)));

// User-related providers
final userNameProvider = StateProvider<String>((ref) => '');
final userRoleProvider = StateProvider<String>((ref) => '');
final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final usersService = ref.watch(usersServiceProvider);
  return await usersService.getUserById(userId);
});

final selectedUserIdProvider = StateProvider<String?>((ref) => null);
final userListProvider = StateProvider<List<UserModel>>((ref) => []);
final filteredUserListProvider = StateProvider<List<UserModel>>((ref) => []);

// Exercise-related providers
final exercisesStreamProvider = StreamProvider<List<ExerciseModel>>((ref) {
  final service = ref.watch(exercisesServiceProvider);
  return service.getExercises();
});

// Role-related providers
final currentUserRoleProvider = StateProvider<String>((ref) {
  final usersService = ref.watch(usersServiceProvider);
  usersService.fetchUserRole();
  return usersService.getCurrentUserRole();
});

// Other providers
final keepWeightProvider = StateProvider<bool>((ref) => false);

// Measurements-related providers
final measurementsProvider = StreamProvider.family<List<MeasurementModel>, String>((ref, userId) {
  final measurementsService = ref.watch(measurementsServiceProvider);
  return measurementsService.getMeasurements(userId: userId);
});

final selectedComparisonsProvider = StateProvider<List<MeasurementModel>>((ref) => []);
final measurementFormProvider = StateNotifierProvider<MeasurementFormNotifier, MeasurementFormState>((ref) => MeasurementFormNotifier());

// Users stream provider
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(usersServiceProvider);
  return service.getUsers();
});
