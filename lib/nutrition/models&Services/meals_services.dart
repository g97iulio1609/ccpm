// meals_services.dart
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
        .collection('meals')
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
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
    });
  }

  Future<meals.Meal?> getMealById(String mealId) async {
    debugPrint('getMealById: Fetching meal with ID: $mealId');
    final mealRef = _firestore.collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      return null;
    }

    return meals.Meal.fromMap(mealSnapshot.data()!);
  }

  Future<String> addMeal(meals.Meal meal, String dailyStatsId) async {
    final mealRef = _firestore.collection('meals').doc();
    meal.id = mealRef.id;
    meal.dailyStatsId = dailyStatsId; // Associa l'ID dailyStats al pasto
    debugPrint('addMeal: Attempting to add meal: ${meal.toMap()}');
    await mealRef.set(meal.toMap());
    debugPrint('addMeal: Meal added with ID: ${mealRef.id}');
    return mealRef.id;
  }

  Future<void> updateMeal(String mealId, meals.Meal updatedMeal) async {
    await _firestore.collection('meals').doc(mealId).update(updatedMeal.toMap());
    notifyListeners();  // Notify listeners when a meal is updated
  }

  Future<void> deleteMeal(String mealId) async {
    await _firestore.collection('meals').doc(mealId).delete();
    notifyListeners();  // Notify listeners when a meal is deleted
  }

  Future<void> addFoodToMeal({required String mealId, required macros.Food food, required double quantity}) async {
    debugPrint('addFoodToMeal: Adding food to meal with ID: $mealId');
    final mealRef = _firestore.collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final mealData = mealSnapshot.data();
    debugPrint('addFoodToMeal: Retrieved meal data: $mealData');

    final meal = meals.Meal.fromMap(mealData!);

    // Create a new document in the 'myfoods' collection
    final myFoodRef = _firestore.collection('myfoods').doc();
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

    // Add the food ID to the meal's foodIds list
    await mealRef.update(meal.toMap());
    notifyListeners();  // Notify listeners when a food is added to a meal
    debugPrint('addFoodToMeal: Food added to meal successfully');

    // Update meal and daily stats with the new food values
    await updateMealAndDailyStats(mealId, food, isAdding: true);
  }

  Future<void> updateFoodInMeal({required String myFoodId, required double newQuantity}) async {
    debugPrint('updateFoodInMeal: Updating food with ID: $myFoodId');
    final myFoodRef = _firestore.collection('myfoods').doc(myFoodId);
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
    debugPrint('updateFoodInMeal: Food updated successfully');
  }

  Future<void> removeFoodFromMeal({required String mealId, required String myFoodId}) async {
    debugPrint('removeFoodFromMeal: Removing food with ID: $myFoodId from meal with ID: $mealId');
    final mealRef = _firestore.collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final meal = meals.Meal.fromFirestore(mealSnapshot);
    
    // Get the food data to update meal and daily stats
    final myFoodRef = _firestore.collection('myfoods').doc(myFoodId);
    final myFoodSnapshot = await myFoodRef.get();
    if (!myFoodSnapshot.exists) {
      throw Exception('Food not found');
    }

    final myFood = macros.Food.fromFirestore(myFoodSnapshot);
    await myFoodRef.delete();
    notifyListeners();  // Notify listeners when a food is removed from a meal
    debugPrint('removeFoodFromMeal: Food removed from meal successfully');

    // Update meal and daily stats with the removed food values
    await updateMealAndDailyStats(mealId, myFood, isAdding: false);
  }

  Future<void> createDailyStatsIfNotExist(String userId, DateTime date) async {
    final dailyStats = await getDailyStatsByDate(userId, date);
    if (dailyStats == null) {
      final newStats = meals.DailyStats(userId: userId, date: date);
      await _firestore.collection('dailyStats').add(newStats.toMap());
      debugPrint('createDailyStatsIfNotExist: DailyStats created for user $userId on $date');
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
          .collection('meals')
          .where('userId', isEqualTo: userId)
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
        final mealId = await addMeal(newMeal, dailyStatsId);
        debugPrint('createMealsIfNotExist: $mealType meal created with ID: $mealId for user $userId on $date');
      } else {
        debugPrint('createMealsIfNotExist: $mealType meal already exists for user $userId on $date');
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
        final dailyStatsRef = _firestore.collection('dailyStats').doc();
        batch.set(dailyStatsRef, newStats.toMap());
      }
    }

    await batch.commit();
    debugPrint('createDailyStatsForMonth: DailyStats created for user $userId for month $month of year $year');
  }

  Future<void> createMealsForMonth(String userId, int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final batch = _firestore.batch();

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dailyStats = await getDailyStatsByDate(userId, date);
      if (dailyStats != null) {
        final dailyStatsId = dailyStats.id!;
        final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

        for (final mealType in mealTypes) {
          final mealQuery = await _firestore
              .collection('meals')
              .where('userId', isEqualTo: userId)
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
            final mealRef = _firestore.collection('meals').doc();
            batch.set(mealRef, newMeal.toMap());
          }
        }
      }
    }

    await batch.commit();
    debugPrint('createMealsForMonth: Meals created for user $userId for month $month of year $year');
  }

  Future<void> createDailyStatsForYear(String userId, int year) async {
    final batch = _firestore.batch();
    for (int month = 1; month <= 12; month++) {
      await createDailyStatsForMonth(userId, year, month);
    }
    await batch.commit();
    debugPrint('createDailyStatsForYear: DailyStats created for user $userId for year $year');
  }

  Future<void> createMealsForYear(String userId, int year) async {
    final batch = _firestore.batch();
    for (int month = 1; month <= 12; month++) {
      await createMealsForMonth(userId, year, month);
    }
    await batch.commit();
    debugPrint('createMealsForYear: Meals created for user $userId for year $year');
  }

  Future<macros.Food?> getMyFoodById(String myFoodId) async {
    final myFoodDoc = await _firestore.collection('myfoods').doc(myFoodId).get();
    if (myFoodDoc.exists) {
      return macros.Food.fromFirestore(myFoodDoc);
    } else {
      return null;
  }}

  Future<meals.DailyStats?> getDailyStatsByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final statsQuery = await _firestore
        .collection('dailyStats')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    if (statsQuery.docs.isNotEmpty) {
      return meals.DailyStats.fromFirestore(statsQuery.docs.first);
    } else {
      return null;
    }
  }

  Future<void> updateMyFood({required String myFoodId, required macros.Food updatedFood}) async {
    debugPrint('updateMyFood: Updating food with ID: $myFoodId');
    final myFoodRef = _firestore.collection('myfoods').doc(myFoodId);
    await myFoodRef.update(updatedFood.toMap());
    notifyListeners(); // Notify listeners when a food is updated
    debugPrint('updateMyFood: Food updated successfully');
  }

  Future<void> addDailyStats(meals.DailyStats stats) async {
    await _firestore.collection('dailyStats').add(stats.toMap());
  }

  Future<void> updateDailyStats(String statsId, meals.DailyStats updatedStats) async {
    await _firestore.collection('dailyStats').doc(statsId).update(updatedStats.toMap());
  }

  Future<void> deleteDailyStats(String statsId) async {
    await _firestore.collection('dailyStats').doc(statsId).delete();
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

  Future<void> updateFood(String foodId, macros.Food updatedFood) async {
    await _firestore.collection('foods').doc(foodId).update(updatedFood.toMap());
  }

  Future<void> deleteFood(String foodId) async {
    await _firestore.collection('foods').doc(foodId).delete();
  }

  Future<List<macros.Food>> getFoodsForMeal(String mealId) async {
    final foodDocs = await _firestore.collection('myfoods').where('mealId', isEqualTo: mealId).get();
    return foodDocs.docs.map((doc) => macros.Food.fromFirestore(doc)).toList();
  }

  Future<void> updateMealAndDailyStats(String mealId, macros.Food food, {required bool isAdding}) async {
    debugPrint('updateMealAndDailyStats: Updating meal and daily stats for meal ID: $mealId');
    final mealRef = _firestore.collection('meals').doc(mealId);
    final mealSnapshot = await mealRef.get();

    if (!mealSnapshot.exists) {
      throw Exception('Meal not found');
    }

    final meal = meals.Meal.fromFirestore(mealSnapshot);

    // Aggiorna i valori nutrizionali del pasto
    meal.totalCalories += isAdding ? food.kcal : -food.kcal;
    meal.totalCarbs += isAdding ? food.carbs : -food.carbs;
    meal.totalFat += isAdding ? food.fat : -food.fat;
    meal.totalProtein += isAdding ? food.protein : -food.protein;

    await mealRef.update(meal.toMap());

    // Aggiorna i valori nutrizionali delle statistiche giornaliere
    final dailyStatsRef = _firestore.collection('dailyStats').doc(meal.dailyStatsId);
    final dailyStatsSnapshot = await dailyStatsRef.get();

    if (!dailyStatsSnapshot.exists) {
      throw Exception('DailyStats not found');
    }

    final dailyStats = meals.DailyStats.fromFirestore(dailyStatsSnapshot);

    dailyStats.totalCalories += isAdding ? food.kcal : -food.kcal;
    dailyStats.totalCarbs += isAdding ? food.carbs : -food.carbs;
    dailyStats.totalFat += isAdding ? food.fat : -food.fat;
    dailyStats.totalProtein += isAdding ? food.protein : -food.protein;

    await dailyStatsRef.update(dailyStats.toMap());

    debugPrint('updateMealAndDailyStats: Meal and daily stats updated successfully');
  }

  Stream<meals.DailyStats> getDailyStatsByDateStream(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('dailyStats')
        .where('userId', isEqualTo: userId)
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
}
