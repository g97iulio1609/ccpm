// diet_plan_services.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diet_plan_model.dart';
import 'meals_services.dart';

final dietPlanServiceProvider = Provider<DietPlanService>((ref) {
  return DietPlanService(ref, FirebaseFirestore.instance);
});

class DietPlanService {
  final ProviderRef ref;
  final FirebaseFirestore _firestore;

  DietPlanService(this.ref, this._firestore);

  // Ottieni la collezione dei piani dietetici per un utente specifico
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

  // Ottieni uno stream di piani dietetici per un utente
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

  // Metodi relativi ai template

  // Ottieni la collezione dei template dei piani dietetici per un admin/coach
  CollectionReference getDietPlanTemplatesCollection(String adminId) {
    return _firestore.collection('users').doc(adminId).collection('dietPlanTemplates');
  }

  // Crea un nuovo piano dietetico come template
  Future<String> createDietPlanTemplate(String adminId, DietPlan dietPlan) async {
    final docRef = await getDietPlanTemplatesCollection(adminId).add(dietPlan.toMap());
    return docRef.id;
  }

  // Ottieni uno stream di tutti i template dietetici per un admin/coach
  Stream<List<DietPlan>> getDietPlanTemplatesStream(String adminId) {
    return getDietPlanTemplatesCollection(adminId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DietPlan.fromFirestore(doc)).toList();
    });
  }

  // Duplica un piano dietetico esistente
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
    final newDietPlan = duplicatedDietPlan.copyWith(id: newDietPlanId);

    // Copia i giorni
    final List<DietPlanDay> duplicatedDays = originalDietPlan.days.map((day) => day.copyWith()).toList();
    final updatedDietPlan = newDietPlan.copyWith(days: duplicatedDays);

    // Aggiorna il nuovo piano dietetico con i giorni duplicati
    await updateDietPlan(updatedDietPlan);

    return newDietPlanId;
  }

  // Applica un piano dietetico all'utente
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
}
