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
      final mealsList = snapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
      _mealsStreamController.add(mealsList);
      notifyListeners();  // Notify listeners when meals change
    });
  }

  Stream<List<meals.Meal>> getMeals() {
    return _mealsStreamController.stream;
  }

  Stream<List<meals.Meal>> getUserMealsByDate({required String userId, required DateTime date}) {
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
      return snapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
    });
  }

  Future<meals.Meal?> getMealById(String userId, String mealId) async {
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      return null;
    }

    return meals.Meal.fromMap(mealSnapshot.data()!);
  }

  Future<String> addMeal(meals.Meal meal, String userId, String dailyStatsId) async {
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc();
    meal.id = mealRef.id;
    meal.dailyStatsId = dailyStatsId; // Associa l'ID dailyStats al pasto
    await mealRef.set(meal.toMap());
    return mealRef.id;
  }

  Future<void> updateMeal(String userId, String mealId, meals.Meal updatedMeal) async {
    await _firestore.collection('users').doc(userId).collection('meals').doc(mealId).update(updatedMeal.toMap());
    notifyListeners();  // Notify listeners when a meal is updated
  }

  Future<void> deleteMeal(String userId, String mealId) async {
    await _firestore.collection('users').doc(userId).collection('meals').doc(mealId).delete();
    notifyListeners();  // Notify listeners when a meal is deleted
  }

  Future<void> addFoodToMeal({required String userId, required String mealId, required macros.Food food, required double quantity}) async {
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

    await myFoodRef.set(myFood);

    await mealRef.update(meal.toMap());
    notifyListeners();  // Notify listeners when a food is added to a meal
    await updateMealAndDailyStats(userId, mealId, food, isAdding: true);
  }

  Future<void> updateFoodInMeal({required String userId, required String myFoodId, required double newQuantity}) async {
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

    await myFoodRef.update(updatedFood);
    notifyListeners();  // Notify listeners when a food is updated
  }

  Future<void> removeFoodFromMeal({required String userId, required String mealId, required String myFoodId}) async {
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final meal = meals.Meal.fromFirestore(mealSnapshot);
    
    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);
    final myFoodSnapshot = await myFoodRef.get();
    if (!myFoodSnapshot.exists) {
      throw Exception('Food not found');
    }

    final myFood = macros.Food.fromFirestore(myFoodSnapshot);
    await myFoodRef.delete();
    notifyListeners();  // Notify listeners when a food is removed from a meal
    await updateMealAndDailyStats(userId, mealId, myFood, isAdding: false);
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
    final sourceFoods = await getFoodsForMeals(userId: userId, mealId: sourceMealId);

    if (overwriteExisting) {
      // Elimina tutti gli alimenti esistenti nel pasto di destinazione
      final targetFoods = await getFoodsForMeals(userId: userId, mealId: targetMealId);
      for (final food in targetFoods) {
        await _firestore.collection('users').doc(userId).collection('myfoods').doc(food.id).delete();
      }
    }

    for (final food in sourceFoods) {
      final duplicatedFood = food.copyWith(id: null, mealId: targetMealId);
      await _firestore.collection('users').doc(userId).collection('myfoods').add(duplicatedFood.toMap());
    }

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
    for (final foodId in foodIds) {
      final foodDoc = await _firestore.collection('users').doc(userId).collection('myfoods').doc(foodId).get();
      if (foodDoc.exists) {
        final foodData = foodDoc.data()!;
        final food = macros.Food.fromMap(foodData).copyWith(mealId: targetMealId);
        await _firestore.collection('users').doc(userId).collection('myfoods').doc(foodId).update(food.toMap());
      }
    }
  }

  Future<void> createDailyStatsIfNotExist(String userId, DateTime date) async {
    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats == null) {
      final newStats = meals.DailyStats(userId: userId, date: date);
      await _firestore.collection('users').doc(userId).collection('dailyStats').add(newStats.toMap());
    }
  }

  Future<void> createMealsIfNotExist(String userId, DateTime date) async {
    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats == null) {
      throw Exception('DailyStats not found for the specified date');
    }

    final dailyStatsId = dailyStats.id!;
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

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
        await addMeal(newMeal, userId, dailyStatsId);
      }
    }
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
      final dailyStats = await getDailyStatsByDate(userId, date);
      if (dailyStats != null) {
        final dailyStatsId = dailyStats.id!;
        final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

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
            await addMeal(newMeal, userId, dailyStatsId);
          }
        }
      }
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

  Future<void> updateMyFood({required String userId, required String myFoodId, required macros.Food updatedFood}) async {
    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);
    await myFoodRef.update(updatedFood.toMap());
    notifyListeners(); // Notify listeners when a food is updated
  }

  Future<void> addDailyStats(String userId, meals.DailyStats stats) async {
    await _firestore.collection('users').doc(userId).collection('dailyStats').add(stats.toMap());
  }

  Future<void> updateDailyStats(String userId, String statsId, meals.DailyStats updatedStats) async {
    await _firestore.collection('users').doc(userId).collection('dailyStats').doc(statsId).update(updatedStats.toMap());
  }

  Future<void> deleteDailyStats(String userId, String statsId) async {
    await _firestore.collection('users').doc(userId).collection('dailyStats').doc(statsId).delete();
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
    await _firestore.collection('foods').add(food.toMap());
  }

  Future<String> createSnack({required String userId, required String dailyStatsId, required DateTime date}) async {
    final snackMeal = meals.Meal(
      userId: userId,
      dailyStatsId: dailyStatsId,
      date: date,
      mealType: 'Snack',
    );
    return await addMeal(snackMeal, userId, dailyStatsId);
  }

  Future<void> deleteSnack({required String userId, required String mealId}) async {
    await deleteMeal(userId, mealId);
  }

  Future<void> updateFood(String foodId, macros.Food updatedFood) async {
    await _firestore.collection('foods').doc(foodId).update(updatedFood.toMap());
  }

  Future<void> deleteFood(String foodId) async {
    await _firestore.collection('foods').doc(foodId).delete();
  }

  Future<List<macros.Food>> getFoodsForMeals({required String userId, required String mealId}) async {
    final foodDocs = await _firestore.collection('users').doc(userId).collection('myfoods').where('mealId', isEqualTo: mealId).get();
    return foodDocs.docs.map((doc) => macros.Food.fromFirestore(doc)).toList();
  }

  Future<void> updateMealAndDailyStats(String userId, String mealId, macros.Food food, {required bool isAdding}) async {
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

    await mealRef.update(meal.toMap());

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

    await dailyStatsRef.update(dailyStats.toMap());
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

  Future<void> saveMealAsFavorite(String userId, String mealId, {String? favoriteName}) async {
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
    );

    await _firestore.collection('users').doc(userId).collection('mymeals').doc(mealId).set(meal.toMap());
  }

  Future<List<meals.Meal>> getFavoriteMeals(String userId) async {
    final favMealsSnapshot = await _firestore.collection('users').doc(userId).collection('mymeals').get();
    return favMealsSnapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
  }

  Future<void> applyFavoriteMealToCurrent(String userId, String favoriteMealId, String currentMealId) async {
    final favoriteMealRef = _firestore.collection('users').doc(userId).collection('mymeals').doc(favoriteMealId);
    final favoriteMealSnapshot = await favoriteMealRef.get();

    if (!favoriteMealSnapshot.exists) {
      throw Exception('Favorite meal not found');
    }

    final favoriteMeal = meals.Meal.fromFirestore(favoriteMealSnapshot);
    final foods = await getFoodsForMeals(userId: userId, mealId: favoriteMealId);

    for (final food in foods) {
      final newFood = food.copyWith(id: null, mealId: currentMealId);
      await _firestore.collection('users').doc(userId).collection('myfoods').add(newFood.toMap());
    }

    for (final food in foods) {
      await updateMealAndDailyStats(userId, currentMealId, food, isAdding: true);
    }
  }
}
