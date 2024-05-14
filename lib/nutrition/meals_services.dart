import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'meals_model.dart';
import 'macros_model.dart';

final mealsServiceProvider = Provider<MealsService>((ref) {
  return MealsService(ref, FirebaseFirestore.instance);
});

class MealsService {
  final ProviderRef ref;
  final FirebaseFirestore _firestore;
  final _mealsStreamController = BehaviorSubject<List<Meal>>();
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
      final meals = snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
      _mealsStreamController.add(meals);
    });
  }

  Stream<List<Meal>> getMeals() {
    return _mealsStreamController.stream;
  }

  Stream<List<Meal>> getUserMealsByDate({required String userId, required DateTime date}) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
    });
  }

  Future<Meal?> getMealById(String mealId) async {
    final mealDoc = await _firestore.collection('meals').doc(mealId).get();
    if (mealDoc.exists) {
      return Meal.fromFirestore(mealDoc);
    } else {
      return null;
    }
  }

  Future<void> addMeal(Meal meal) async {
    await _firestore.collection('meals').add(meal.toMap());
  }

  Future<void> updateMeal(String mealId, Meal updatedMeal) async {
    await _firestore.collection('meals').doc(mealId).update(updatedMeal.toMap());
  }

  Future<void> deleteMeal(String mealId) async {
    await _firestore.collection('meals').doc(mealId).delete();
  }

  Future<void> addFoodToMeal({
    required String mealId,
    required Food food,
  }) async {
    final mealDoc = await _firestore.collection('meals').doc(mealId).get();
    if (mealDoc.exists) {
      final meal = Meal.fromFirestore(mealDoc);
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
    required Food food,
  }) async {
    final mealDoc = await _firestore.collection('meals').doc(mealId).get();
    if (mealDoc.exists) {
      final meal = Meal.fromFirestore(mealDoc);
      meal.foodIds.remove(food.id);
      meal.totalCalories -= food.kcal;
      meal.totalCarbs -= food.carbs;
      meal.totalFat -= food.fat;
      meal.totalProtein -= food.protein;
      await updateMeal(mealId, meal);
    }
  }
}
