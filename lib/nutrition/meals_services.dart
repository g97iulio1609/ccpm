import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'meals_model.dart' as meals;
import 'macros_model.dart' as macros;

final mealsServiceProvider = Provider<MealsService>((ref) {
  return MealsService(ref, FirebaseFirestore.instance);
});

class MealsService {
  final ProviderRef ref;
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
    final mealDoc = await _firestore.collection('meals').doc(mealId).get();
    if (mealDoc.exists) {
      return meals.Meal.fromFirestore(mealDoc);
    } else {
      return null;
    }
  }

  Future<void> addMeal(meals.Meal meal) async {
    await _firestore.collection('meals').add(meal.toMap());
  }

  Future<void> updateMeal(String mealId, meals.Meal updatedMeal) async {
    await _firestore.collection('meals').doc(mealId).update(updatedMeal.toMap());
  }

  Future<void> deleteMeal(String mealId) async {
    await _firestore.collection('meals').doc(mealId).delete();
  }

  Future<void> addFoodToMeal({
    required String mealId,
    required macros.Food food,
  }) async {
    final mealDoc = await _firestore.collection('meals').doc(mealId).get();
    if (mealDoc.exists) {
      final meal = meals.Meal.fromFirestore(mealDoc);
      meal.foodIds.add(food.id!);
      meal.totalCalories += food.kcal;
      meal.totalCarbs += food.carbs;
      meal.totalFat += food.fat;
      meal.totalProtein += food.protein;
      await updateMeal(mealId, meal);
    }
  }

  Future<void> removeFoodFromMeal({
    required String mealId,
    required macros.Food food,
  }) async {
    final mealDoc = await _firestore.collection('meals').doc(mealId).get();
    if (mealDoc.exists) {
      final meal = meals.Meal.fromFirestore(mealDoc);
      meal.foodIds.remove(food.id);
      meal.totalCalories -= food.kcal;
      meal.totalCarbs -= food.carbs;
      meal.totalFat -= food.fat;
      meal.totalProtein -= food.protein;
      await updateMeal(mealId, meal);
    }
  }

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
}
