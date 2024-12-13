// lib/providers/providers.dart
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
import 'package:shared_preferences/shared_preferences.dart';

import '../services/users_services.dart';
import '../services/tdee_services.dart';
import '../ExerciseRecords/exercise_record_services.dart';
import '../measurements/measurements_services.dart';
import '../exerciseManager/exercises_services.dart';
import '../Coaching/coaching_service.dart';

import '../models/measurement_model.dart';
import '../models/user_model.dart';
import '../exerciseManager/exercise_model.dart';

// Importa i servizi AI separatamente
// Non importa ai_providers.dart qui per evitare conflitti

// Provider per Firebase Auth
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Provider per Firebase Firestore
final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider per Firebase Functions
final firebaseFunctionsProvider =
    Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);

// Provider per UsersService
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, ref.watch(firebaseFirestoreProvider),
      ref.watch(firebaseAuthProvider));
});

// Provider per verifica admin
final isAdminProvider = StateProvider<bool>((ref) => false);

// Provider per TDEEService
final tdeeServiceProvider = Provider<TDEEService>(
    (ref) => TDEEService(ref.watch(firebaseFirestoreProvider)));

// Provider per ExerciseRecordService
final exerciseRecordServiceProvider = Provider<ExerciseRecordService>((ref) {
  return ExerciseRecordService(FirebaseFirestore.instance);
});

// Provider per MeasurementsService
final measurementsServiceProvider = Provider<MeasurementsService>(
    (ref) => MeasurementsService(ref.watch(firebaseFirestoreProvider)));

// Provider per ExercisesService
final exercisesServiceProvider = Provider<ExercisesService>((ref) {
  return ExercisesService(ref.watch(firebaseFirestoreProvider));
});

// Provider per CoachingService
final coachingServiceProvider = Provider<CoachingService>(
    (ref) => CoachingService(ref.watch(firebaseFirestoreProvider)));

// Provider per TrainingProgramService
final trainingServiceProvider = Provider<TrainingProgramService>((ref) {
  final firestoreService = FirestoreService();
  return TrainingProgramService(firestoreService);
});

// Provider per User Name
final userNameProvider = StateProvider<String>((ref) => '');

// Provider per User Role
final userRoleProvider = StateProvider<String>((ref) => '');

// Provider per ottenere un utente specifico
final userProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final usersService = ref.watch(usersServiceProvider);
  return await usersService.getUserById(userId);
});

// Provider per query di ricerca utenti
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider per stream di utenti
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(usersServiceProvider);
  return service.getUsers();
});

// Provider per lista utenti
final userListProvider = StateProvider<List<UserModel>>((ref) => []);

// Provider per lista utenti filtrata
final filteredUserListProvider = StateProvider<List<UserModel>>((ref) {
  return [];
});

// Provider per stream di esercizi
final exercisesStreamProvider = StreamProvider<List<ExerciseModel>>((ref) {
  final service = ref.watch(exercisesServiceProvider);
  return service.getExercises();
});

// Provider per ruolo utente corrente
final currentUserRoleProvider = StateProvider<String>((ref) {
  final usersService = ref.watch(usersServiceProvider);
  usersService.fetchUserRole();
  return usersService.getCurrentUserRole();
});

// Provider per mantenere il peso
final keepWeightProvider = StateProvider<bool>((ref) => false);

// Provider per stream di misurazioni
final measurementsProvider =
    StreamProvider.family<List<MeasurementModel>, String>((ref, userId) {
  final measurementsService = ref.watch(measurementsServiceProvider);
  return measurementsService.getMeasurements(userId: userId);
});

// Provider per confronti selezionati
final selectedComparisonsProvider =
    StateProvider<List<MeasurementModel>>((ref) => []);

// Provider per form di misurazione
final measurementFormProvider =
    StateNotifierProvider<MeasurementFormNotifier, MeasurementFormState>(
        (ref) => MeasurementFormNotifier());

// Provider per ID utente selezionato
final selectedUserIdProvider = StateProvider<String?>((ref) {
  return null;
});

// Provider per dettagli della sottoscrizione
final subscriptionDetailsProvider =
    StateProvider<SubscriptionDetails?>((ref) => null);

// Provider per sottoscrizione dell'utente selezionato
final selectedUserSubscriptionProvider =
    StateProvider<SubscriptionDetails?>((ref) => null);

// Provider per caricamento della sottoscrizione
final subscriptionLoadingProvider = StateProvider<bool>((ref) => false);

// Provider per gestione della sottoscrizione
final managingSubscriptionProvider = StateProvider<bool>((ref) => false);

// Provider per sincronizzazione
final syncingProvider = StateProvider<bool>((ref) => false);

// Provider per ExerciseService
final exerciseServiceProvider = Provider<ExercisesService>((ref) {
  return ExercisesService(ref.watch(firebaseFirestoreProvider));
});

// Provider per TrainingProgram
final trainingProgramProvider =
    FutureProvider.family<TrainingProgram?, String>((ref, userId) async {
  final trainingService = ref.watch(trainingServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  final user = await usersService.getUserById(userId);
  if (user == null || user.currentProgram == null) return null;
  return await trainingService.fetchTrainingProgram(user.currentProgram!);
});

// Provider per NutritionStats
final nutritionStatsProvider =
    FutureProvider.family<NutritionStats?, String>((ref, userId) async {
  final nutritionService = ref.watch(nutritionServiceProvider);
  return await nutritionService.getDailyStats(userId);
});

// Provider per ultime misurazioni
final latestMeasurementsProvider =
    FutureProvider.family<MeasurementModel?, String>((ref, userId) async {
  final measurementsService = ref.watch(measurementsServiceProvider);
  final measurements =
      await measurementsService.getMeasurements(userId: userId).first;
  return measurements.isNotEmpty ? measurements.first : null;
});

// Provider per record personali
final personalRecordsProvider =
    StreamProvider.family<List<ExerciseRecord>, String>((ref, userId) {
  final recordService = ref.watch(exerciseRecordServiceProvider);
  return recordService.getExerciseRecords(userId: userId, exerciseId: '');
});

// Provider per record di esercizi
final exerciseRecordsProvider =
    StreamProvider.family<List<ExerciseRecord>, String>((ref, userId) {
  final service = ref.watch(exerciseRecordServiceProvider);
  return service.getExerciseRecords(userId: userId, exerciseId: '');
});

// Provider per NutritionService
final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService(ref.watch(firebaseFirestoreProvider));
});

// Provider per misurazioni precedenti
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

// Definizione del provider per SharedPreferences
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});
