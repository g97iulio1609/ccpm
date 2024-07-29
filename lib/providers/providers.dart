import 'package:alphanessone/models/measurement_model.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/providers/measurement_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/users_services.dart';
import '../services/tdee_services.dart';
import '../services/exercise_record_services.dart';
import '../services/measurements_services.dart';

// User-related providers
final userNameProvider = StateProvider<String>((ref) => '');
final userRoleProvider = StateProvider<String>((ref) => '');
// Add this provider
final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final usersService = ref.watch(usersServiceProvider);
  return await usersService.getUserById(userId);
});

// Firebase-related providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Service providers
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(
    ref,
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final tdeeServiceProvider = Provider<TDEEService>((ref) {
  return TDEEService(ref.watch(firebaseFirestoreProvider));
});

final exerciseRecordServiceProvider = Provider<ExerciseRecordService>((ref) {
  return ExerciseRecordService(ref.watch(firebaseFirestoreProvider));
});

final measurementsServiceProvider = Provider<MeasurementsService>((ref) {
  return MeasurementsService(ref.watch(firebaseFirestoreProvider));
});

// Measurements-related providers
final measurementsProvider = StreamProvider.family<List<MeasurementModel>, String>((ref, userId) {
  final measurementsService = ref.watch(measurementsServiceProvider);
  return measurementsService.getMeasurements(userId: userId);
});

final selectedComparisonsProvider = StateProvider<List<MeasurementModel>>((ref) {
  return [];
});

final measurementFormProvider = StateNotifierProvider<MeasurementFormNotifier, MeasurementFormState>((ref) {
  return MeasurementFormNotifier();
});

final selectedUserIdProvider = StateProvider<String?>((ref) => null);
