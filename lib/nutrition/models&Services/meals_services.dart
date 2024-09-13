// meals_services.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/macros_model.dart' as macros;

final mealsServiceProvider = ChangeNotifierProvider<MealsService>((ref) {
  return MealsService(ref, FirebaseFirestore.instance);
});

class MealsService extends ChangeNotifier {
  final ChangeNotifierProviderRef<MealsService> ref;
  final FirebaseFirestore _firestore;
  final _mealsStreamController = BehaviorSubject<List<meals.Meal>>();
  StreamSubscription? _mealsChangesSubscription;

  MealsService(this.ref, this._firestore) {
    _initializeMealsStream();
  }

  void _initializeMealsStream() {
    _mealsChangesSubscription?.cancel();
    _mealsChangesSubscription = _firestore
        .collectionGroup('meals')
        .snapshots()
        .listen((snapshot) {
      final mealsList =
          snapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
      _mealsStreamController.add(mealsList);
      notifyListeners(); // Notify listeners when meals change
    });
  }

  Stream<List<meals.Meal>> getMeals() {
    return _mealsStreamController.stream;
  }

  Stream<List<meals.Meal>> getUserMealsByDate({
    required String userId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => meals.Meal.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<macros.Food>> getFoodsForMealStream({
    required String userId,
    required String mealId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .where('mealId', isEqualTo: mealId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => macros.Food.fromFirestore(doc))
          .toList();
    });
  }

  Future<meals.Meal?> getMealById(String userId, String mealId) async {
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      return null;
    }

    return meals.Meal.fromMap(mealSnapshot.data()!);
  }

  Future<String> addMeal(meals.Meal meal, String userId, String dailyStatsId) async {
    final batch = _firestore.batch();
    final mealRef =
        _firestore.collection('users').doc(userId).collection('meals').doc();
    meal.id = mealRef.id;
    meal.dailyStatsId = dailyStatsId; // Associa l'ID dailyStats al pasto
    batch.set(mealRef, meal.toMap());
    await batch.commit();
    return mealRef.id;
  }

  Future<void> updateMeal(
      String userId, String mealId, meals.Meal updatedMeal) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    batch.update(mealRef, updatedMeal.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a meal is updated
  }

  Future<void> deleteMeal(String userId, String mealId) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    batch.delete(mealRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a meal is deleted
  }

  Future<void> addFoodToMeal({
    required String userId,
    required String mealId,
    required macros.Food food,
    required double quantity,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final mealData = mealSnapshot.data();
    final meal = meals.Meal.fromMap(mealData!);

    final myFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc();
    final myFood = macros.Food(
      id: myFoodRef.id,
      mealId: mealId,
      name: food.name,
      kcal: food.kcal * quantity / 100,
      carbs: food.carbs * quantity / 100,
      fat: food.fat * quantity / 100,
      protein: food.protein * quantity / 100,
      quantity: quantity,
      portion: food.portion,
      // Aggiungi altri campi se necessario
    );

    batch.set(myFoodRef, myFood.toMap());
    batch.update(mealRef, meal.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is added to a meal
    await updateMealAndDailyStats(userId, mealId, myFood, isAdding: true);
  }

  Future<void> updateFoodInMeal({
    required String userId,
    required String myFoodId,
    required double newQuantity,
  }) async {
    final batch = _firestore.batch();
    final myFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc(myFoodId);
    final myFoodSnapshot = await myFoodRef.get();

    if (!myFoodSnapshot.exists) {
      throw Exception('Food not found');
    }

    final myFoodData = myFoodSnapshot.data()!;
    final oldQuantity = myFoodData['quantity'];
    final adjustmentFactor = newQuantity / oldQuantity;

    final updatedFood = {
      'kcal': myFoodData['kcal'] * adjustmentFactor,
      'carbs': myFoodData['carbs'] * adjustmentFactor,
      'fat': myFoodData['fat'] * adjustmentFactor,
      'protein': myFoodData['protein'] * adjustmentFactor,
      'quantity': newQuantity,
      // Aggiorna altri campi se necessario
    };

    batch.update(myFoodRef, updatedFood);
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is updated

    // Recupera l'ID del pasto associato
    final mealId = myFoodData['mealId'];
    // Aggiorna le statistiche del pasto e giornaliere
    final food = macros.Food.fromMap(myFoodData).copyWith(
      id: myFoodId,
      mealId: mealId,
      quantity: newQuantity,
    );
    await updateMealAndDailyStats(userId, mealId, food, isAdding: true);
  }

  Future<void> removeFoodFromMeal({
    required String userId,
    required String mealId,
    required String myFoodId,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final myFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc(myFoodId);
    final myFoodSnapshot = await myFoodRef.get();
    if (!myFoodSnapshot.exists) {
      throw Exception('Food not found');
    }

    final myFood = macros.Food.fromFirestore(myFoodSnapshot);
    batch.delete(myFoodRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is removed from a meal
    await updateMealAndDailyStats(userId, mealId, myFood, isAdding: false);
  }

  Future<void> removeFoodFromFavoriteMeal({
    required String userId,
    required String mealId,
    required String myFoodId,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('mymeals')
        .doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final myFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc(myFoodId);
    final myFoodSnapshot = await myFoodRef.get();

    if (!myFoodSnapshot.exists) {
      throw Exception('Food not found');
    }

    batch.delete(myFoodRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is removed from a meal
  }

  Future<Map<String, double>> getTotalNutrientsForMeal(
      String userId, String mealId) async {
    final foods =
        await getFoodsForMeals(userId: userId, mealId: mealId);
    double totalCarbs = 0;
    double totalProteins = 0;
    double totalFats = 0;
    double totalCalories = 0;

    for (final food in foods) {
      totalCarbs += food.carbs;
      totalProteins += food.protein;
      totalFats += food.fat;
      totalCalories += food.kcal;
    }

    return {
      'carbs': totalCarbs,
      'proteins': totalProteins,
      'fats': totalFats,
      'calories': totalCalories,
    };
  }

  Future<void> duplicateMeal({
    required String userId,
    required String sourceMealId,
    required String targetMealId,
    required bool overwriteExisting,
  }) async {
    final batch = _firestore.batch();
    final sourceFoods = await getFoodsForMeals(
        userId: userId, mealId: sourceMealId);

    if (overwriteExisting) {
      // Elimina tutti gli alimenti esistenti nel pasto di destinazione
      final targetFoods = await getFoodsForMeals(
          userId: userId, mealId: targetMealId);
      for (final food in targetFoods) {
        final foodRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('myfoods')
            .doc(food.id);
        batch.delete(foodRef);
      }
    }

    for (final food in sourceFoods) {
      final duplicatedFood = food.copyWith(
        id: null,
        mealId: targetMealId,
      );
      final foodRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('myfoods')
          .doc();
      batch.set(foodRef, duplicatedFood.toMap());
    }

    await batch.commit();

    // Aggiorna le statistiche del pasto e del giorno di destinazione
    for (final food in sourceFoods) {
      final updatedFood = food.copyWith(
        mealId: targetMealId,
      );
      await updateMealAndDailyStats(userId, targetMealId, updatedFood,
          isAdding: true);
    }
  }

  Future<void> moveFoods({
    required String userId,
    required List<String> foodIds,
    required String targetMealId,
  }) async {
    final batch = _firestore.batch();
    for (final foodId in foodIds) {
      final foodDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('myfoods')
          .doc(foodId)
          .get();
      if (foodDoc.exists) {
        final foodData = foodDoc.data()!;
        final food = macros.Food.fromMap(foodData).copyWith(
          mealId: targetMealId,
        );
        final foodRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('myfoods')
            .doc(foodId);
        batch.update(foodRef, food.toMap());
      }
    }
    await batch.commit();
  }

  Future<void> createDailyStatsIfNotExist(
      String userId, DateTime date) async {
    final batch = _firestore.batch();
    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats == null) {
      final newStats = meals.DailyStats(
        userId: userId,
        date: date,
      );
      final statsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyStats')
          .doc();
      batch.set(statsRef, newStats.toMap());
    }
    await batch.commit();
  }

  Future<void> createMealsIfNotExist(
      String userId, DateTime date) async {
    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats == null) {
      throw Exception('DailyStats not found for the specified date');
    }

    final dailyStatsId = dailyStats.id!;
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final batch = _firestore.batch();

    for (final mealType in mealTypes) {
      final mealQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .where('dailyStatsId', isEqualTo: dailyStatsId)
          .where('mealType', isEqualTo: mealType)
          .get();

      if (mealQuery.docs.isEmpty) {
        final newMeal = meals.Meal(
          userId: userId,
          dailyStatsId: dailyStatsId,
          date: date,
          mealType: mealType,
        );
        final mealRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('meals')
            .doc();
        batch.set(mealRef, newMeal.toMap());
      }
    }
    await batch.commit();
  }

  Future<void> createDailyStatsForMonth(
      String userId, int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final batch = _firestore.batch();

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dailyStats = await getDailyStatsByDate(userId, date);
      if (dailyStats == null) {
        final newStats = meals.DailyStats(
          userId: userId,
          date: date,
        );
        final statsRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('dailyStats')
            .doc();
        batch.set(statsRef, newStats.toMap());
      }
    }

    await batch.commit();
  }

  Future<void> createMealsForMonth(
      String userId, int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      await createDailyStatsIfNotExist(userId, date);
      await createMealsIfNotExist(userId, date);
    }
  }

  Future<void> createDailyStatsForYear(
      String userId, int year) async {
    for (int month = 1; month <= 12; month++) {
      await createDailyStatsForMonth(userId, year, month);
    }
  }

  Future<void> createMealsForYear(
      String userId, int year) async {
    for (int month = 1; month <= 12; month++) {
      await createMealsForMonth(userId, year, month);
    }
  }

  Future<macros.Food?> getMyFoodById(
      String userId, String myFoodId) async {
    final myFoodDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc(myFoodId)
        .get();
    if (myFoodDoc.exists) {
      return macros.Food.fromFirestore(myFoodDoc);
    } else {
      return null;
    }
  }

  Future<meals.DailyStats?> getDailyStatsByDate(
      String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final statsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (statsQuery.docs.isNotEmpty) {
      return meals.DailyStats.fromFirestore(statsQuery.docs.first);
    } else {
      return null;
    }
  }

  Future<void> updateMyFood({
    required String userId,
    required String myFoodId,
    required macros.Food updatedFood,
  }) async {
    final batch = _firestore.batch();
    final myFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc(myFoodId);
    batch.update(myFoodRef, updatedFood.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is updated
  }

  Future<void> addDailyStats(
      String userId, meals.DailyStats stats) async {
    final batch = _firestore.batch();
    final statsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc();
    batch.set(statsRef, stats.toMap());
    await batch.commit();
  }

  Future<void> updateDailyStats(
      String userId, String statsId, meals.DailyStats updatedStats) async {
    final batch = _firestore.batch();
    final statsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc(statsId);
    batch.update(statsRef, updatedStats.toMap());
    await batch.commit();
  }

  Future<void> deleteDailyStats(
      String userId, String statsId) async {
    final batch = _firestore.batch();
    final statsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc(statsId);
    batch.delete(statsRef);
    await batch.commit();
  }

  Future<macros.Food?> getFoodById(String foodId) async {
    final foodDoc = await _firestore
        .collection('foods')
        .doc(foodId)
        .get();
    if (foodDoc.exists) {
      return macros.Food.fromFirestore(foodDoc);
    } else {
      return null;
    }
  }

  Future<void> addFood(macros.Food food) async {
    final batch = _firestore.batch();
    final foodRef = _firestore.collection('foods').doc();
    batch.set(foodRef, food.toMap());
    await batch.commit();
  }

  Future<String> createSnack({
    required String userId,
    required String dailyStatsId,
    required DateTime date,
  }) async {
    final batch = _firestore.batch();
    final snackMeal = meals.Meal(
      userId: userId,
      dailyStatsId: dailyStatsId,
      date: date,
      mealType: 'Snack',
    );
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc();
    batch.set(mealRef, snackMeal.toMap());
    await batch.commit();
    return mealRef.id;
  }

  Future<void> deleteSnack({
    required String userId,
    required String mealId,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    batch.delete(mealRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a snack is deleted
  }

  Future<void> updateFood(
      String foodId, macros.Food updatedFood) async {
    final batch = _firestore.batch();
    final foodRef =
        _firestore.collection('foods').doc(foodId);
    batch.update(foodRef, updatedFood.toMap());
    await batch.commit();
  }

  Future<void> deleteFood(String foodId) async {
    final batch = _firestore.batch();
    final foodRef =
        _firestore.collection('foods').doc(foodId);
    batch.delete(foodRef);
    await batch.commit();
  }

  Future<List<macros.Food>> getFoodsForMeals({
    required String userId,
    required String mealId,
  }) async {
    final foodDocs = await _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .where('mealId', isEqualTo: mealId)
        .get();
    return foodDocs.docs.map((doc) => macros.Food.fromFirestore(doc)).toList();
  }

  Future<void> updateMealAndDailyStats(
    String userId,
    String mealId,
    macros.Food food, {
    required bool isAdding,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final meal = meals.Meal.fromFirestore(mealSnapshot);

    meal.totalCalories =
        (meal.totalCalories + (isAdding ? food.kcal : -food.kcal))
            .clamp(0, double.infinity);
    meal.totalCarbs =
        (meal.totalCarbs + (isAdding ? food.carbs : -food.carbs))
            .clamp(0, double.infinity);
    meal.totalFat =
        (meal.totalFat + (isAdding ? food.fat : -food.fat))
            .clamp(0, double.infinity);
    meal.totalProtein =
        (meal.totalProtein + (isAdding ? food.protein : -food.protein))
            .clamp(0, double.infinity);

    batch.update(mealRef, meal.toMap());

    final dailyStatsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc(meal.dailyStatsId);
    final dailyStatsSnapshot = await dailyStatsRef.get();

    if (!dailyStatsSnapshot.exists) {
      throw Exception('DailyStats not found');
    }

    final dailyStats =
        meals.DailyStats.fromFirestore(dailyStatsSnapshot);

    dailyStats.totalCalories =
        (dailyStats.totalCalories + (isAdding ? food.kcal : -food.kcal))
            .clamp(0, double.infinity);
    dailyStats.totalCarbs =
        (dailyStats.totalCarbs + (isAdding ? food.carbs : -food.carbs))
            .clamp(0, double.infinity);
    dailyStats.totalFat =
        (dailyStats.totalFat + (isAdding ? food.fat : -food.fat))
            .clamp(0, double.infinity);
    dailyStats.totalProtein =
        (dailyStats.totalProtein + (isAdding ? food.protein : -food.protein))
            .clamp(0, double.infinity);

    batch.update(dailyStatsRef, dailyStats.toMap());
    await batch.commit();
  }

  // Metodo aggiornato per creare pasti da un piano dietetico, duplicando anche gli alimenti
Future<void> createMealsFromMealIds(String userId, DateTime date, List<String> mealIds) async {
  final dailyStatsId = await _getOrCreateDailyStatsId(userId, date);
  final batch = _firestore.batch();

  for (String mealId in mealIds) {
    final meal = await getMealById(userId, mealId);
    if (meal != null) {
      final mealType = meal.mealType;

      // Query per verificare se esiste già un pasto dello stesso tipo nella data di destinazione
      final existingMealsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where('mealType', isEqualTo: mealType)
          .get();

      if (existingMealsSnapshot.docs.isNotEmpty) {
        // Il pasto esiste, sovrascrivere
        final existingMealDoc = existingMealsSnapshot.docs.first;
        final existingMeal = meals.Meal.fromFirestore(existingMealDoc);

        // Elimina tutti gli alimenti associati al pasto esistente
        final existingFoodsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('myfoods')
            .where('mealId', isEqualTo: existingMeal.id)
            .get();

        for (final foodDoc in existingFoodsSnapshot.docs) {
          batch.delete(foodDoc.reference);
        }

        // Aggiorna il pasto esistente con la nuova data e dailyStatsId
        batch.update(existingMealDoc.reference, {
          'date': Timestamp.fromDate(date),
          'dailyStatsId': dailyStatsId,
          // Altri campi da aggiornare se necessario
        });

        // Duplica gli alimenti dal pasto originale al pasto esistente
        final originalFoods = await getFoodsForMeals(userId: userId, mealId: mealId);
        for (final food in originalFoods) {
          final duplicatedFood = food.copyWith(
            id: null, // Lascia che Firestore assegni un nuovo ID
            mealId: existingMeal.id!, // Associa al pasto esistente (uso di !)
          );
          final foodRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('myfoods')
              .doc();
          batch.set(foodRef, duplicatedFood.toMap());

          // Aggiorna le statistiche del pasto e giornaliere per il nuovo alimento
          // Nota: updateMealAndDailyStats è asincrono, ma non può essere chiamato all'interno di un batch
          // Devi chiamarlo dopo il commit del batch
        }
      } else {
        // Il pasto non esiste, creare un nuovo pasto
        final newMeal = meal.copyWith(
          id: null, // Lascia che Firestore assegni un nuovo ID
          date: date,
          dailyStatsId: dailyStatsId,
        );

        final newMealRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('meals')
            .doc();
        batch.set(newMealRef, newMeal.toMap());

        // Recupera gli alimenti associati al pasto originale
        final originalFoods = await getFoodsForMeals(userId: userId, mealId: mealId);

        // Duplica ciascun alimento e associarlo al nuovo pasto
        for (final food in originalFoods) {
          final duplicatedFood = food.copyWith(
            id: null, // Lascia che Firestore assegni un nuovo ID
            mealId: newMealRef.id, // Associa al nuovo pasto
          );
          final foodRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('myfoods')
              .doc();
          batch.set(foodRef, duplicatedFood.toMap());

          // Aggiorna le statistiche del pasto e giornaliere per il nuovo alimento
          // Nota: updateMealAndDailyStats è asincrono, ma non può essere chiamato all'interno di un batch
          // Devi chiamarlo dopo il commit del batch
        }
      }
    }
  }

  // Commit del batch
  await batch.commit();

  // Ora aggiorna le statistiche per tutti i pasti modificati
  for (String mealId in mealIds) {
    final meal = await getMealById(userId, mealId);
    if (meal != null) {
      final originalFoods = await getFoodsForMeals(userId: userId, mealId: mealId);
      for (final food in originalFoods) {
        await updateMealAndDailyStats(userId, meal.id!, food, isAdding: true); // Uso di !
      }
    }
  }
}
  Future<String> _getOrCreateDailyStatsId(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final statsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (statsQuery.docs.isNotEmpty) {
      return statsQuery.docs.first.id;
    } else {
      // Crea un nuovo dailyStats
      final newStatsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyStats')
          .doc();
      await newStatsRef.set({
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'totalCalories': 0.0,
        'totalCarbs': 0.0,
        'totalFat': 0.0,
        'totalProtein': 0.0,
      });
      return newStatsRef.id;
    }
  }

  // Metodo per creare pasti da un DailyDiet
  Future<void> createMealsFromDailyDiet(
      String userId, DateTime date, List<meals.Meal> mealsList) async {
    final mealsCollection =
        _firestore.collection('users').doc(userId).collection('meals');

    for (final meal in mealsList) {
      // Controlla se il pasto esiste già per questa data e tipo
      final querySnapshot = await mealsCollection
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where('mealType', isEqualTo: meal.mealType)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Crea un nuovo pasto
        final newMealRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('meals')
            .doc();
        final newMeal = meal.copyWith(
          id: newMealRef.id,
          date: date,
          dailyStatsId: meal.dailyStatsId, // Assicurati che dailyStatsId sia corretto
        );
        await newMealRef.set(newMeal.toMap());
      } else {
        // Opzionalmente, puoi aggiornare il pasto esistente o ignorarlo
        // Per esempio, aggiornare il pasto esistente:
        final existingMeal = meals.Meal.fromFirestore(querySnapshot.docs.first);
        final updatedMeal = existingMeal.copyWith(
          // Aggiorna i campi necessari se desideri modificare il pasto esistente
        );
        await querySnapshot.docs.first.reference.update(updatedMeal.toMap());
      }
    }
  }

  Future<String> saveMealAsFavorite(
    String userId,
    String mealId, {
    String? favoriteName,
    required String dailyStatsId,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final mealData = mealSnapshot.data()!;
    final mealType = mealData['mealType'];
    final mealDate = (mealData['date'] as Timestamp).toDate();
    final defaultFavoriteName =
        '$mealType ${mealDate.day}/${mealDate.month}/${mealDate.year}';

    final meal = meals.Meal.fromFirestore(mealSnapshot).copyWith(
      isFavorite: true,
      favoriteName: favoriteName ?? defaultFavoriteName,
      dailyStatsId: dailyStatsId, // Utilizza il dailyStatsId passato come parametro
    );

    final newMealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('mymeals')
        .doc();
    batch.set(newMealRef, meal.toMap());
    await batch.commit();
    return newMealRef.id;
  }

  Future<List<meals.Meal>> getFavoriteMeals(String userId) async {
    final favMealsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mymeals')
        .get();
    return favMealsSnapshot.docs
        .map((doc) => meals.Meal.fromFirestore(doc))
        .toList();
  }

  Future<void> applyFavoriteMealToCurrent(
    String userId,
    String favoriteMealId,
    String currentMealId,
  ) async {
    final batch = _firestore.batch();
    final favoriteMealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('mymeals')
        .doc(favoriteMealId);
    final favoriteMealSnapshot = await favoriteMealRef.get();

    if (!favoriteMealSnapshot.exists) {
      throw Exception('Favorite meal not found');
    }

    final foods = await getFoodsForMeals(userId: userId, mealId: favoriteMealId);

    for (final food in foods) {
      final newFood = food.copyWith(
        id: null, // Lascia che Firestore assegni un nuovo ID
        mealId: currentMealId, // Associa al pasto corrente
      );
      final myFoodRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('myfoods')
          .doc();
      batch.set(myFoodRef, newFood.toMap());

      // Aggiorna le statistiche del pasto e giornaliere per il nuovo alimento
      await updateMealAndDailyStats(userId, currentMealId, newFood, isAdding: true);
    }

    await batch.commit();
  }

  Future<void> saveDayAsFavorite(
    String userId,
    DateTime date, {
    String? favoriteName,
  }) async {
    final batch = _firestore.batch();
    final favoriteDayRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('mydays')
        .doc();
    final favoriteDay = meals.FavoriteDay(
      id: favoriteDayRef.id,
      userId: userId,
      date: date,
      favoriteName:
          favoriteName ?? 'Favorite Day ${date.day}/${date.month}/${date.year}',
    );

    batch.set(favoriteDayRef, favoriteDay.toMap());

    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats != null) {
      final mealsForDay = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .where('dailyStatsId', isEqualTo: dailyStats.id)
          .get();

      for (final mealDoc in mealsForDay.docs) {
        final meal = meals.Meal.fromFirestore(mealDoc);
        final newMealId = await saveMealAsFavorite(
          userId,
          meal.id!,
          favoriteName: meal.mealType,
          dailyStatsId: favoriteDay.id!,
        );

        // Copia gli alimenti associati al pasto nel nuovo pasto preferito
        final foodsForMeal = await _firestore
            .collection('users')
            .doc(userId)
            .collection('myfoods')
            .where('mealId', isEqualTo: meal.id!)
            .get();

        for (final foodDoc in foodsForMeal.docs) {
          final food = macros.Food.fromFirestore(foodDoc);
          final newFood = food.copyWith(id: null, mealId: newMealId);
          final myFoodRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('myfoods')
              .doc();
          batch.set(myFoodRef, newFood.toMap());
        }
      }
    }

    await batch.commit();
  }

  Future<List<meals.FavoriteDay>> getFavoriteDays(String userId) async {
    final favDaysSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mydays')
        .get();
    return favDaysSnapshot.docs
        .map((doc) => meals.FavoriteDay.fromFirestore(doc))
        .toList();
  }

  Future<void> addFoodToFavoriteMeal({
    required String userId,
    required String mealId,
    required macros.Food food,
    required double quantity,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('mymeals')
        .doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final mealData = mealSnapshot.data()!;
    final meal = meals.Meal.fromMap(mealData);

    final myFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc();
    final myFood = macros.Food(
      id: myFoodRef.id,
      mealId: mealId,
      name: food.name,
      kcal: food.kcal * quantity / 100,
      carbs: food.carbs * quantity / 100,
      fat: food.fat * quantity / 100,
      protein: food.protein * quantity / 100,
      quantity: quantity,
      portion: food.portion,
      // Aggiungi altri campi se necessario
    );

    batch.set(myFoodRef, myFood.toMap());
    batch.update(mealRef, meal.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is added to a meal
    await updateMealAndDailyStats(userId, mealId, myFood, isAdding: true);
  }

  Future<void> applyFavoriteDayToCurrent(
    String userId,
    String favoriteDayId,
    DateTime date,
  ) async {
    final batch = _firestore.batch();

    // Crea daily stats per il giorno corrente
    await createDailyStatsIfNotExist(userId, date);
    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats == null || dailyStats.id == null) {
      throw Exception('DailyStats not found for the specified date');
    }

    final favoriteDayRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('mydays')
        .doc(favoriteDayId);
    final favoriteDaySnapshot = await favoriteDayRef.get();

    if (!favoriteDaySnapshot.exists) {
      throw Exception('Favorite day not found');
    }

    final favoriteDay = meals.FavoriteDay.fromFirestore(favoriteDaySnapshot);

    // Ottieni i pasti del giorno corrente
    final currentMealsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('dailyStatsId', isEqualTo: dailyStats.id!)
        .get();

    final currentMeals =
        currentMealsSnapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
    final currentSnacks =
        currentMeals.where((meal) => meal.mealType.startsWith('Snack')).toList();

    // Ottieni i pasti preferiti per questo giorno
    final favoriteMealsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mymeals')
        .where('dailyStatsId', isEqualTo: favoriteDay.id)
        .get();

    final favoriteMeals = favoriteMealsSnapshot.docs
        .map((doc) => meals.Meal.fromFirestore(doc))
        .toList();
    final favoriteSnacks =
        favoriteMeals.where((meal) => meal.mealType.startsWith('Snack')).toList();

    // Creazione di snack aggiuntivi se necessario
    if (favoriteSnacks.length > currentSnacks.length) {
      for (int i = currentSnacks.length; i < favoriteSnacks.length; i++) {
        final newSnackRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('meals')
            .doc();
        final newSnack = meals.Meal(
          id: newSnackRef.id,
          userId: userId,
          dailyStatsId: dailyStats.id!,
          date: date,
          mealType: 'Snack ${i + 1}',
        );
        batch.set(newSnackRef, newSnack.toMap());
        currentMeals.add(newSnack);
      }
    }

    // Applica i pasti preferiti ai pasti correnti
    for (final favoriteMeal in favoriteMeals) {
      final currentMeal = currentMeals.firstWhere(
        (meal) => meal.mealType == favoriteMeal.mealType,
        orElse: () => meals.Meal.emptyMeal(
            userId, dailyStats.id!, date, favoriteMeal.mealType),
      );

      final newMealRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(currentMeal.id);
      final updatedMeal = favoriteMeal.copyWith(
        id: currentMeal.id,
        dailyStatsId: dailyStats.id!,
        date: date,
      );
      batch.set(newMealRef, updatedMeal.toMap());

      // Copia gli alimenti associati al pasto preferito nel nuovo pasto
      final foodsForFavoriteMealSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('myfoods')
          .where('mealId', isEqualTo: favoriteMeal.id)
          .get();

      for (final foodDoc in foodsForFavoriteMealSnapshot.docs) {
        final food = macros.Food.fromFirestore(foodDoc);
        final newFood = food.copyWith(id: null, mealId: currentMeal.id!);

        final myFoodRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('myfoods')
            .doc();
        batch.set(myFoodRef, newFood.toMap());

        // Aggiorna le statistiche del pasto e giornaliere per il nuovo alimento
        await updateMealAndDailyStats(userId, currentMeal.id!, newFood, isAdding: true);
      }
    }

    await batch.commit();
    notifyListeners();
  }

  @override
  void dispose() {
    _mealsChangesSubscription?.cancel();
    _mealsStreamController.close();
    super.dispose();
  }

  Future<void> deleteMealsByDate(String userId, DateTime date) async {
    final mealsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .get();

    final batch = _firestore.batch();
    for (var doc in mealsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

   Stream<meals.DailyStats> getDailyStatsByDateStream(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return meals.DailyStats.fromFirestore(snapshot.docs.first);
      } else {
        throw Exception('DailyStats not found');
      }
    });
  }
  Future<void> deleteFavoriteDay(String userId, String favoriteDayId) async {
    final batch = _firestore.batch();
    final favoriteDayRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('mydays')
        .doc(favoriteDayId);
    batch.delete(favoriteDayRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a favorite day is deleted
  }
  Future<void> deleteFavoriteMeal(String userId, String favoriteMealId) async {
    final batch = _firestore.batch();
    final favoriteMealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc(favoriteMealId);
    batch.delete(favoriteMealRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a favorite meal is deleted
  }
}
