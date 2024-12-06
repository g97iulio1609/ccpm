// providers.dart
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:alphanessone/measurements/measurements_provider.dart';
import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/models/nutrition_stats.dart';
import 'package:alphanessone/services/nutrition_service.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/trainingBuilder/services/training_services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa i servizi necessari
import '../services/users_services.dart';
import '../services/tdee_services.dart';
import '../ExerciseRecords/exercise_record_services.dart';
import '../measurements/measurements_services.dart';
import '../exerciseManager/exercises_services.dart';
import '../Coaching/coaching_service.dart';

// Importa i modelli
import '../models/measurement_model.dart';
import '../models/user_model.dart';
import '../exerciseManager/exercise_model.dart';

// Firebase-related providers
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseFunctionsProvider =
    Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);

// Service providers
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, ref.watch(firebaseFirestoreProvider),
      ref.watch(firebaseAuthProvider));
});
final isAdminProvider = StateProvider<bool>((ref) => false);

final tdeeServiceProvider = Provider<TDEEService>(
    (ref) => TDEEService(ref.watch(firebaseFirestoreProvider)));
final exerciseRecordServiceProvider = Provider<ExerciseRecordService>((ref) {
  return ExerciseRecordService(FirebaseFirestore.instance);
});
final measurementsServiceProvider = Provider<MeasurementsService>(
    (ref) => MeasurementsService(ref.watch(firebaseFirestoreProvider)));
final exercisesServiceProvider = Provider<ExercisesService>((ref) {
  return ExercisesService(ref.watch(firebaseFirestoreProvider));
});
final coachingServiceProvider = Provider<CoachingService>(
    (ref) => CoachingService(ref.watch(firebaseFirestoreProvider)));

final trainingServiceProvider = Provider<TrainingProgramService>((ref) {
  final firestoreService = FirestoreService();
  return TrainingProgramService(firestoreService);
});

// User-related providers
final userNameProvider = StateProvider<String>((ref) => '');
final userRoleProvider = StateProvider<String>((ref) => '');
final userProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final usersService = ref.watch(usersServiceProvider);
  return await usersService.getUserById(userId);
});

// Provider per la query di ricerca degli utenti
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Users stream provider
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(usersServiceProvider);
  return service.getUsers();
});

// Provider per la lista completa degli utenti
final userListProvider = StateProvider<List<UserModel>>((ref) => []);

// Provider per la lista filtrata degli utenti basata sulla query di ricerca
final filteredUserListProvider = StateProvider<List<UserModel>>((ref) {
  return [];
});

// Provider per lo stream delle esercitazioni
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
final measurementsProvider =
    StreamProvider.family<List<MeasurementModel>, String>((ref, userId) {
  final measurementsService = ref.watch(measurementsServiceProvider);
  return measurementsService.getMeasurements(userId: userId);
});

final selectedComparisonsProvider =
    StateProvider<List<MeasurementModel>>((ref) => []);
final measurementFormProvider =
    StateNotifierProvider<MeasurementFormNotifier, MeasurementFormState>(
        (ref) => MeasurementFormNotifier());

// User selection providers
final selectedUserIdProvider = StateProvider<String?>((ref) {
  return null;
});

// New Providers for SubscriptionsScreen
final subscriptionDetailsProvider =
    StateProvider<SubscriptionDetails?>((ref) => null);
final selectedUserSubscriptionProvider =
    StateProvider<SubscriptionDetails?>((ref) => null);
final subscriptionLoadingProvider = StateProvider<bool>((ref) => false);
final managingSubscriptionProvider = StateProvider<bool>((ref) => false);
final syncingProvider = StateProvider<bool>((ref) => false);

// Provider per il servizio degli esercizi
final exerciseServiceProvider = Provider<ExercisesService>((ref) {
  return ExercisesService(ref.watch(firebaseFirestoreProvider));
});

// Training Program Provider
final trainingProgramProvider =
    FutureProvider.family<TrainingProgram?, String>((ref, userId) async {
  final trainingService = ref.watch(trainingServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  final user = await usersService.getUserById(userId);
  if (user == null || user.currentProgram == null) return null;
  return await trainingService.fetchTrainingProgram(user.currentProgram!);
});

// Nutrition Stats Provider
final nutritionStatsProvider =
    FutureProvider.family<NutritionStats?, String>((ref, userId) async {
  final nutritionService = ref.watch(nutritionServiceProvider);
  return await nutritionService.getDailyStats(userId);
});

// Latest Measurements Provider
final latestMeasurementsProvider =
    FutureProvider.family<MeasurementModel?, String>((ref, userId) async {
  final measurementsService = ref.watch(measurementsServiceProvider);
  final measurements =
      await measurementsService.getMeasurements(userId: userId).first;
  return measurements.isNotEmpty ? measurements.first : null;
});

// Personal Records Provider
final personalRecordsProvider =
    StreamProvider.family<List<ExerciseRecord>, String>((ref, userId) {
  final recordService = ref.watch(exerciseRecordServiceProvider);
  return recordService.getExerciseRecords(userId: userId, exerciseId: '');
});

// Exercise Records Provider
final exerciseRecordsProvider =
    StreamProvider.family<List<ExerciseRecord>, String>((ref, userId) {
  final service = ref.watch(exerciseRecordServiceProvider);
  return service.getExerciseRecords(userId: userId, exerciseId: '');
});

// Nutrition Service
final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService(ref.watch(firebaseFirestoreProvider));
});

// Add a new provider for previous measurements
final previousMeasurementsProvider =
    StreamProvider<List<MeasurementModel>>((ref) {
  final measurementsService = ref.watch(measurementsServiceProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);

  return firestore
      .collection('users')
      .doc(auth.currentUser?.uid)
      .collection('measurements')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MeasurementModel.fromJson(doc.data()))
          .toList());
});
