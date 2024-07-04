import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'meals_model.dart' as meals;
import 'macros_model.dart' as macros;

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

  Stream<List<meals.Meal>> getUserMealsByDate(
      {required String userId, required DateTime date}) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => meals.Meal.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<macros.Food>> getFoodsForMealStream(
      {required String userId, required String mealId}) {
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
    final mealRef =
        _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      return null;
    }

    return meals.Meal.fromMap(mealSnapshot.data()!);
  }

  Future<String> addMeal(meals.Meal meal, String userId, String dailyStatsId) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc();
    meal.id = mealRef.id;
    meal.dailyStatsId = dailyStatsId; // Associa l'ID dailyStats al pasto
    batch.set(mealRef, meal.toMap());
    await batch.commit();
    return mealRef.id;
  }

  Future<void> updateMeal(String userId, String mealId, meals.Meal updatedMeal) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    batch.update(mealRef, updatedMeal.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a meal is updated
  }

  Future<void> deleteMeal(String userId, String mealId) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
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
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final mealData = mealSnapshot.data();
    final meal = meals.Meal.fromMap(mealData!);

    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();
    final myFood = {
      'mealId': mealId,
      'name': food.name,
      'kcal': food.kcal * quantity / 100,
      'carbs': food.carbs * quantity / 100,
      'fat': food.fat * quantity / 100,
      'protein': food.protein * quantity / 100,
      'quantity': quantity,
      'quantityUnit': food.quantityUnit,
      'portion': food.portion,
      'sugar': food.sugar * quantity / 100,
      'fiber': food.fiber * quantity / 100,
      'saturatedFat': food.saturatedFat * quantity / 100,
      'polyunsaturatedFat': food.polyunsaturatedFat * quantity / 100,
      'monounsaturatedFat': food.monounsaturatedFat * quantity / 100,
      'transFat': food.transFat * quantity / 100,
      'cholesterol': food.cholesterol * quantity / 100,
      'sodium': food.sodium * quantity / 100,
      'potassium': food.potassium * quantity / 100,
      'vitaminA': food.vitaminA * quantity / 100,
      'vitaminC': food.vitaminC * quantity / 100,
      'calcium': food.calcium * quantity / 100,
      'iron': food.iron * quantity / 100,
    };

    batch.set(myFoodRef, myFood);
    batch.update(mealRef, meal.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is added to a meal
    await updateMealAndDailyStats(userId, mealId, food, isAdding: true);
  }

  Future<void> updateFoodInMeal({
    required String userId,
    required String myFoodId,
    required double newQuantity,
  }) async {
    final batch = _firestore.batch();
    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);
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
      'sugar': myFoodData['sugar'] * adjustmentFactor,
      'fiber': myFoodData['fiber'] * adjustmentFactor,
      'saturatedFat': myFoodData['saturatedFat'] * adjustmentFactor,
      'polyunsaturatedFat': myFoodData['polyunsaturatedFat'] * adjustmentFactor,
      'monounsaturatedFat': myFoodData['monounsaturatedFat'] * adjustmentFactor,
      'transFat': myFoodData['transFat'] * adjustmentFactor,
      'cholesterol': myFoodData['cholesterol'] * adjustmentFactor,
      'sodium': myFoodData['sodium'] * adjustmentFactor,
      'potassium': myFoodData['potassium'] * adjustmentFactor,
      'vitaminA': myFoodData['vitaminA'] * adjustmentFactor,
      'vitaminC': myFoodData['vitaminC'] * adjustmentFactor,
      'calcium': myFoodData['calcium'] * adjustmentFactor,
      'iron': myFoodData['iron'] * adjustmentFactor,
    };

    batch.update(myFoodRef, updatedFood);
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is updated

    // Recupera l'ID del pasto associato
    final mealId = myFoodData['mealId'];
    // Aggiorna le statistiche del pasto e giornaliere
    final food = macros.Food.fromMap(myFoodData).copyWith(id: myFoodId, mealId: mealId, quantity: newQuantity);
    await updateMealAndDailyStats(userId, mealId, food, isAdding: true);
  }

  Future<void> removeFoodFromMeal({
    required String userId,
    required String mealId,
    required String myFoodId,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }


    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);
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
    final mealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);
    final myFoodSnapshot = await myFoodRef.get();

    if (!myFoodSnapshot.exists) {
      throw Exception('Food not found');
    }

    batch.delete(myFoodRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is removed from a meal
  }

  Future<Map<String, double>> getTotalNutrientsForMeal(String userId, String mealId) async {
    final foods = await getFoodsForMeals(userId: userId, mealId: mealId);
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
    final sourceFoods = await getFoodsForMeals(userId: userId, mealId: sourceMealId);

    if (overwriteExisting) {
      // Elimina tutti gli alimenti esistenti nel pasto di destinazione
      final targetFoods = await getFoodsForMeals(userId: userId, mealId: targetMealId);
      for (final food in targetFoods) {
        final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(food.id);
        batch.delete(foodRef);
      }
    }

    for (final food in sourceFoods) {
      final duplicatedFood = food.copyWith(id: null, mealId: targetMealId);
      final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();
      batch.set(foodRef, duplicatedFood.toMap());
    }

    await batch.commit();

    // Aggiorna le statistiche del pasto e del giorno di destinazione
    for (final food in sourceFoods) {
      final updatedFood = food.copyWith(mealId: targetMealId);
      await updateMealAndDailyStats(userId, targetMealId, updatedFood, isAdding: true);
    }
  }

  Future<void> moveFoods({
    required String userId,
    required List<String> foodIds,
    required String targetMealId,
  }) async {
    final batch = _firestore.batch();
    for (final foodId in foodIds) {
      final foodDoc = await _firestore.collection('users').doc(userId).collection('myfoods').doc(foodId).get();
      if (foodDoc.exists) {
        final foodData = foodDoc.data()!;
        final food = macros.Food.fromMap(foodData).copyWith(mealId: targetMealId);
        final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(foodId);
        batch.update(foodRef, food.toMap());
      }
    }
    await batch.commit();
  }

  Future<void> createDailyStatsIfNotExist(String userId, DateTime date) async {
    final batch = _firestore.batch();
    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats == null) {
      final newStats = meals.DailyStats(userId: userId, date: date);
      final statsRef = _firestore.collection('users').doc(userId).collection('dailyStats').doc();
      batch.set(statsRef, newStats.toMap());
    }
    await batch.commit();
  }

  Future<void> createMealsIfNotExist(String userId, DateTime date) async {
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
        final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc();
        batch.set(mealRef, newMeal.toMap());
      }
    }
    await batch.commit();
  }

  Future<void> createDailyStatsForMonth(String userId, int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final batch = _firestore.batch();

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dailyStats = await getDailyStatsByDate(userId, date);
      if (dailyStats == null) {
        final newStats = meals.DailyStats(userId: userId, date: date);
        final dailyStatsRef = _firestore.collection('users').doc(userId).collection('dailyStats').doc();
        batch.set(dailyStatsRef, newStats.toMap());
      }
    }

    await batch.commit();
  }

  Future<void> createMealsForMonth(String userId, int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      await createDailyStatsIfNotExist(userId, date);
      await createMealsIfNotExist(userId, date);
    }
  }

  Future<void> createDailyStatsForYear(String userId, int year) async {
    for (int month = 1; month <= 12; month++) {
      await createDailyStatsForMonth(userId, year, month);
    }
  }

  Future<void> createMealsForYear(String userId, int year) async {
    for (int month = 1; month <= 12; month++) {
      await createMealsForMonth(userId, year, month);
    }
  }

  Future<macros.Food?> getMyFoodById(String userId, String myFoodId) async {
    final myFoodDoc = await _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId).get();
    if (myFoodDoc.exists) {
      return macros.Food.fromFirestore(myFoodDoc);
    } else {
      return null;
    }
  }

  Future<meals.DailyStats?> getDailyStatsByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final statsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
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
    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);
    batch.update(myFoodRef, updatedFood.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is updated
  }

  Future<void> addDailyStats(String userId, meals.DailyStats stats) async {
    final batch = _firestore.batch();
    final statsRef = _firestore.collection('users').doc(userId).collection('dailyStats').doc();
    batch.set(statsRef, stats.toMap());
    await batch.commit();
  }

  Future<void> updateDailyStats(String userId, String statsId, meals.DailyStats updatedStats) async {
    final batch = _firestore.batch();
    final statsRef = _firestore.collection('users').doc(userId).collection('dailyStats').doc(statsId);
    batch.update(statsRef, updatedStats.toMap());
    await batch.commit();
  }

  Future<void> deleteDailyStats(String userId, String statsId) async {
    final batch = _firestore.batch();
    final statsRef = _firestore.collection('users').doc(userId).collection('dailyStats').doc(statsId);
    batch.delete(statsRef);
    await batch.commit();
  }

  Future<macros.Food?> getFoodById(String foodId) async {
    final foodDoc = await _firestore.collection('foods').doc(foodId).get();
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
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc();
    batch.set(mealRef, snackMeal.toMap());
    await batch.commit();
    return mealRef.id;
  }

  Future<void> deleteSnack({required String userId, required String mealId}) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    batch.delete(mealRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a snack is deleted
  }

  Future<void> updateFood(String foodId, macros.Food updatedFood) async {
    final batch = _firestore.batch();
    final foodRef = _firestore.collection('foods').doc(foodId);
    batch.update(foodRef, updatedFood.toMap());
    await batch.commit();
  }

  Future<void> deleteFood(String foodId) async {
    final batch = _firestore.batch();
    final foodRef = _firestore.collection('foods').doc(foodId);
    batch.delete(foodRef);
    await batch.commit();
  }

  Future<List<macros.Food>> getFoodsForMeals({
    required String userId,
    required String mealId,
  }) async {
    final foodDocs = await _firestore.collection('users').doc(userId).collection('myfoods').where('mealId', isEqualTo: mealId).get();
    return foodDocs.docs.map((doc) => macros.Food.fromFirestore(doc)).toList();
  }

  Future<void> updateMealAndDailyStats(
    String userId,
    String mealId,
    macros.Food food, {
    required bool isAdding,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final meal = meals.Meal.fromFirestore(mealSnapshot);

    meal.totalCalories = (meal.totalCalories + (isAdding ? food.kcal : -food.kcal)).clamp(0, double.infinity);
    meal.totalCarbs = (meal.totalCarbs + (isAdding ? food.carbs : -food.carbs)).clamp(0, double.infinity);
    meal.totalFat = (meal.totalFat + (isAdding ? food.fat : -food.fat)).clamp(0, double.infinity);
    meal.totalProtein = (meal.totalProtein + (isAdding ? food.protein : -food.protein)).clamp(0, double.infinity);

    batch.update(mealRef, meal.toMap());

    final dailyStatsRef = _firestore.collection('users').doc(userId).collection('dailyStats').doc(meal.dailyStatsId);
    final dailyStatsSnapshot = await dailyStatsRef.get();

    if (!dailyStatsSnapshot.exists) {
      throw Exception('DailyStats not found');
    }

    final dailyStats = meals.DailyStats.fromFirestore(dailyStatsSnapshot);

    dailyStats.totalCalories = (dailyStats.totalCalories + (isAdding ? food.kcal : -food.kcal)).clamp(0, double.infinity);
    dailyStats.totalCarbs = (dailyStats.totalCarbs + (isAdding ? food.carbs : -food.carbs)).clamp(0, double.infinity);
    dailyStats.totalFat = (dailyStats.totalFat + (isAdding ? food.fat : -food.fat)).clamp(0, double.infinity);
    dailyStats.totalProtein = (dailyStats.totalProtein + (isAdding ? food.protein : -food.protein)).clamp(0, double.infinity);

    batch.update(dailyStatsRef, dailyStats.toMap());
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

  Future<String> saveMealAsFavorite(
    String userId,
    String mealId, {
    String? favoriteName,
    required String dailyStatsId,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final mealData = mealSnapshot.data()!;
    final mealType = mealData['mealType'];
    final mealDate = (mealData['date'] as Timestamp).toDate();
    final defaultFavoriteName = '$mealType ${mealDate.day}/${mealDate.month}/${mealDate.year}';

    final meal = meals.Meal.fromFirestore(mealSnapshot).copyWith(
      isFavorite: true,
      favoriteName: favoriteName ?? defaultFavoriteName,
      dailyStatsId: dailyStatsId, // Utilizza il dailyStatsId passato come parametro
    );

    final newMealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc();
    batch.set(newMealRef, meal.toMap());
    await batch.commit();
    return newMealRef.id;
  }

  Future<List<meals.Meal>> getFavoriteMeals(String userId) async {
    final favMealsSnapshot = await _firestore.collection('users').doc(userId).collection('mymeals').get();
    return favMealsSnapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
  }

  Future<void> applyFavoriteMealToCurrent(
    String userId,
    String favoriteMealId,
    String currentMealId,
  ) async {
    final batch = _firestore.batch();
    final favoriteMealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc(favoriteMealId);
    final favoriteMealSnapshot = await favoriteMealRef.get();

    if (!favoriteMealSnapshot.exists) {
      throw Exception('Favorite meal not found');
    }

    final foods = await getFoodsForMeals(userId: userId, mealId: favoriteMealId);

    for (final food in foods) {
      final newFood = food.copyWith(id: null, mealId: currentMealId);
      final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();
      batch.set(myFoodRef, newFood.toMap());
    }

    await batch.commit();

    for (final food in foods) {
      await updateMealAndDailyStats(userId, currentMealId, food, isAdding: true);
    }
  }

  Future<void> deleteFavoriteMeal(String userId, String favoriteMealId) async {
    final batch = _firestore.batch();
    final favoriteMealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc(favoriteMealId);
    batch.delete(favoriteMealRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a favorite meal is deleted
  }

  Future<void> saveDayAsFavorite(String userId, DateTime date, {String? favoriteName}) async {
    final batch = _firestore.batch();
    final favoriteDayRef = _firestore.collection('users').doc(userId).collection('mydays').doc();
    final favoriteDay = meals.FavoriteDay(
      id: favoriteDayRef.id,
      userId: userId,
      date: date,
      favoriteName: favoriteName ?? 'Favorite Day ${date.day}/${date.month}/${date.year}',
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
        final newMealId = await saveMealAsFavorite(userId, meal.id!, favoriteName: meal.mealType, dailyStatsId: favoriteDay.id!);

        // Copia gli alimenti associati al pasto nel nuovo pasto preferito
        final foodsForMeal = await _firestore
            .collection('users')
            .doc(userId)
            .collection('myfoods')
            .where('mealId', isEqualTo: meal.id)
            .get();

        for (final foodDoc in foodsForMeal.docs) {
          final food = macros.Food.fromFirestore(foodDoc);
          final newFood = food.copyWith(id: null, mealId: newMealId);
          final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();
          batch.set(myFoodRef, newFood.toMap());
        }
      }
    }

    await batch.commit();
  }

  Future<List<meals.FavoriteDay>> getFavoriteDays(String userId) async {
    final favDaysSnapshot = await _firestore.collection('users').doc(userId).collection('mydays').get();
    return favDaysSnapshot.docs.map((doc) => meals.FavoriteDay.fromFirestore(doc)).toList();
  }

  Future<void> addFoodToFavoriteMeal({
    required String userId,
    required String mealId,
    required macros.Food food,
    required double quantity,
  }) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final mealData = mealSnapshot.data();
    final meal = meals.Meal.fromMap(mealData!);

    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();
    final myFood = {
      'mealId': mealId,
      'name': food.name,
      'kcal': food.kcal * quantity / 100,
      'carbs': food.carbs * quantity / 100,
      'fat': food.fat * quantity / 100,
      'protein': food.protein * quantity / 100,
      'quantity': quantity,
      'quantityUnit': food.quantityUnit,
      'portion': food.portion,
      'sugar': food.sugar * quantity / 100,
      'fiber': food.fiber * quantity / 100,
      'saturatedFat': food.saturatedFat * quantity / 100,
      'polyunsaturatedFat': food.polyunsaturatedFat * quantity / 100,
      'monounsaturatedFat': food.monounsaturatedFat * quantity / 100,
      'transFat': food.transFat * quantity / 100,
      'cholesterol': food.cholesterol * quantity / 100,
      'sodium': food.sodium * quantity / 100,
      'potassium': food.potassium * quantity / 100,
      'vitaminA': food.vitaminA * quantity / 100,
      'vitaminC': food.vitaminC * quantity / 100,
      'calcium': food.calcium * quantity / 100,
      'iron': food.iron * quantity / 100,
    };

    batch.set(myFoodRef, myFood);
    batch.update(mealRef, meal.toMap());
    await batch.commit();
    notifyListeners(); // Notify listeners when a food is added to a meal
    await updateMealAndDailyStats(userId, mealId, food, isAdding: true);
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

  final favoriteDayRef = _firestore.collection('users').doc(userId).collection('mydays').doc(favoriteDayId);
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

  final currentMeals = currentMealsSnapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
  final currentSnacks = currentMeals.where((meal) => meal.mealType.startsWith('Snack')).toList();

  // Ottieni i pasti preferiti per questo giorno
  final favoriteMealsSnapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('mymeals')
      .where('dailyStatsId', isEqualTo: favoriteDay.id)
      .get();

  final favoriteMeals = favoriteMealsSnapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
  final favoriteSnacks = favoriteMeals.where((meal) => meal.mealType.startsWith('Snack')).toList();

  // Creazione di snack aggiuntivi se necessario
  if (favoriteSnacks.length > currentSnacks.length) {
    for (int i = currentSnacks.length; i < favoriteSnacks.length; i++) {
      final newSnackRef = _firestore.collection('users').doc(userId).collection('meals').doc();
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
      orElse: () => meals.Meal.emptyMeal(userId, dailyStats.id!, date, favoriteMeal.mealType),
    );

    final newMealRef = _firestore.collection('users').doc(userId).collection('meals').doc(currentMeal.id);
    final updatedMeal = favoriteMeal.copyWith(id: currentMeal.id, dailyStatsId: dailyStats.id!, date: date);
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

      final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();
      batch.set(myFoodRef, newFood.toMap());
    }
  }

  await batch.commit();
  notifyListeners();
}

  Future<String> createMealFromFavorite(
    String userId,
    String favoriteMealId,
    DateTime date,
    String newDailyStatsId,
  ) async {
    final batch = _firestore.batch();
    final favoriteMealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc(favoriteMealId);
    final favoriteMealSnapshot = await favoriteMealRef.get();

    if (!favoriteMealSnapshot.exists) {
      throw Exception('Favorite meal not found');
    }

    final favoriteMeal = meals.Meal.fromFirestore(favoriteMealSnapshot);

    final newMeal = favoriteMeal.copyWith(
      id: null,
      dailyStatsId: newDailyStatsId,
      date: date,
    );

    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc();
    batch.set(mealRef, newMeal.toMap());
    await batch.commit();
    return mealRef.id;
  }

  Future<void> deleteFavoriteDay(String userId, String favoriteDayId) async {
    final batch = _firestore.batch();
    final favoriteDayRef = _firestore.collection('users').doc(userId).collection('mydays').doc(favoriteDayId);
    batch.delete(favoriteDayRef);
    await batch.commit();
    notifyListeners(); // Notify listeners when a favorite day is deleted
  }
}
