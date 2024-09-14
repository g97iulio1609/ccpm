// providers/diet_plan_services.dart
import 'package:alphanessone/nutrition/models&Services/diet_plan_model.dart';
import 'package:alphanessone/nutrition/models&Services/meals_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dietPlanServiceProvider = Provider<DietPlanService>((ref) {
  return DietPlanService(ref, FirebaseFirestore.instance);
});

class DietPlanService {
  final ProviderRef ref;
  final FirebaseFirestore _firestore;

  DietPlanService(this.ref, this._firestore);

  // Ottieni la collezione dei piani dietetici per un utente
  CollectionReference getDietPlansCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('dietPlans');
  }

  // Crea un nuovo piano dietetico
  Future<String> createDietPlan(DietPlan dietPlan) async {
    final docRef = await getDietPlansCollection(dietPlan.userId).add(dietPlan.toMap());
    return docRef.id;
  }

  // Aggiorna un piano dietetico esistente
  Future<void> updateDietPlan(DietPlan dietPlan) async {
    if (dietPlan.id == null) throw Exception('DietPlan ID is null');
    await getDietPlansCollection(dietPlan.userId).doc(dietPlan.id).update(dietPlan.toMap());
  }

  // Elimina un piano dietetico
  Future<void> deleteDietPlan(String userId, String dietPlanId) async {
    await getDietPlansCollection(userId).doc(dietPlanId).delete();
  }

  // Ottieni uno stream di tutti i piani dietetici per un utente
  Stream<List<DietPlan>> getDietPlansStream(String userId) {
    return getDietPlansCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DietPlan.fromFirestore(doc)).toList();
    });
  }

  // Ottieni un piano dietetico per ID
  Future<DietPlan?> getDietPlanById(String userId, String dietPlanId) async {
    final doc = await getDietPlansCollection(userId).doc(dietPlanId).get();
    if (doc.exists) {
      return DietPlan.fromFirestore(doc);
    }
    return null;
  }

  // Applica un piano dietetico al periodo definito utilizzando batch
  Future<void> applyDietPlan(DietPlan dietPlan) async {
    final userId = dietPlan.userId;
    final startDate = dietPlan.startDate;
    final durationDays = dietPlan.durationDays;

    final mealsService = ref.read(mealsServiceProvider);
    final batch = _firestore.batch();

    for (int i = 0; i < durationDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dayOfWeek = _getDayOfWeek(currentDate.weekday);

      // Trova il DietPlanDay corrispondente al giorno della settimana
      final dietPlanDay = dietPlan.days.firstWhere(
        (day) => day.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase(),
        orElse: () => DietPlanDay(dayOfWeek: dayOfWeek, mealIds: []),
      );

      // Crea i pasti per la data corrente utilizzando gli ID selezionati
      await mealsService.createMealsFromMealIdsBatch(userId, currentDate, dietPlanDay.mealIds, batch);
    }

    // Esegui tutte le operazioni in batch
    await batch.commit();
  }

  // Crea più piani dietetici in batch
  Future<List<String>> createMultipleDietPlans(List<DietPlan> dietPlans) async {
    final batch = _firestore.batch();
    final createdIds = <String>[];

    for (final dietPlan in dietPlans) {
      final docRef = getDietPlansCollection(dietPlan.userId).doc();
      batch.set(docRef, dietPlan.toMap());
      createdIds.add(docRef.id);
    }

    await batch.commit();
    return createdIds;
  }
  
  

  // Aggiorna più piani dietetici in batch
  Future<void> updateMultipleDietPlans(List<DietPlan> dietPlans) async {
    final batch = _firestore.batch();

    for (final dietPlan in dietPlans) {
      if (dietPlan.id == null) throw Exception('DietPlan ID is null');
      final docRef = getDietPlansCollection(dietPlan.userId).doc(dietPlan.id);
      batch.update(docRef, dietPlan.toMap());
    }

    await batch.commit();
  }

  // Elimina più piani dietetici in batch
  Future<void> deleteMultipleDietPlans(String userId, List<String> dietPlanIds) async {
    final batch = _firestore.batch();

    for (final id in dietPlanIds) {
      final docRef = getDietPlansCollection(userId).doc(id);
      batch.delete(docRef);
    }

    await batch.commit();
  }

  // Utility per ottenere il nome del giorno della settimana
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  /// Duplicare un piano dietetico esistente
  Future<String> duplicateDietPlan(String userId, String dietPlanId, {String? newName}) async {
    // Ottieni il piano dietetico originale
    final originalDietPlan = await getDietPlanById(userId, dietPlanId);
    if (originalDietPlan == null) {
      throw Exception('DietPlan not found');
    }

    // Crea una copia del piano dietetico con un nuovo ID e (opzionalmente) un nuovo nome
    final duplicatedDietPlan = originalDietPlan.copyWith(
      id: null, // Firestore genererà un nuovo ID
      name: newName ?? '${originalDietPlan.name} (Copy)',
      startDate: DateTime.now(), // Puoi decidere come gestire la data di inizio
    );

    // Crea il nuovo piano dietetico
    final newDietPlanId = await createDietPlan(duplicatedDietPlan);

    // Recupera i pasti associati al piano originale
    final originalDays = originalDietPlan.days;

    // Copia i pasti per ciascun giorno
    for (final day in originalDays) {
      // Copia le mealIds per il nuovo piano dietetico
      final duplicatedDay = day.copyWith(
        mealIds: List<String>.from(day.mealIds),
      );

      // Aggiorna il piano dietetico con i giorni duplicati
      await updateDietPlan(DietPlan(
        id: newDietPlanId,
        userId: duplicatedDietPlan.userId,
        name: duplicatedDietPlan.name,
        startDate: duplicatedDietPlan.startDate,
        durationDays: duplicatedDietPlan.durationDays,
        days: [...duplicatedDietPlan.days, duplicatedDay],
      ));
    }

    return newDietPlanId;
  }
}
