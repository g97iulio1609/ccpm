// meals_services.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../models/meals_model.dart' as meals;
import '../models/macros_model.dart' as macros;

final mealsServiceProvider = ChangeNotifierProvider<MealsService>((ref) {
  return MealsService(ref, FirebaseFirestore.instance);
});

class MealsService extends ChangeNotifier {
  final Ref ref;
  final FirebaseFirestore _firestore;

  // Cache per i pasti e le statistiche giornaliere
  final _mealsCache = <String, meals.Meal>{};
  final _dailyStatsCache = <String, meals.DailyStats>{};
  final _foodsCache = <String, macros.Food>{};

  // Stream controllers ottimizzati
  final _mealsStreamController = BehaviorSubject<List<meals.Meal>>();
  final _dailyStatsStreamController = BehaviorSubject<meals.DailyStats>();

  // Subscription management
  final _subscriptions = <StreamSubscription>[];

  // Batch operations queue
  final _batchQueue = <Future Function()>[];
  bool _isBatchProcessing = false;

  MealsService(this.ref, this._firestore) {
    _initializeService();
  }

  void _initializeService() {
    // Inizializza i listener principali
    _subscriptions.add(_firestore.collectionGroup('meals').snapshots().listen(_handleMealsUpdate));
  }

  void _handleMealsUpdate(QuerySnapshot snapshot) {
    // Genera la lista e aggiorna cache + stream
    _mealsStreamController.add(
      snapshot.docs.map((doc) {
        final meal = meals.Meal.fromFirestore(doc);
        _mealsCache[meal.id!] = meal;
        return meal;
      }).toList(),
    );
    notifyListeners();
  }

  // Ottimizzazione delle query con cache
  Future<meals.Meal?> getMealById(String userId, String mealId) async {
    if (_mealsCache.containsKey(mealId)) {
      return _mealsCache[mealId];
    }

    final mealDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId)
        .get();

    if (!mealDoc.exists) return null;

    final meal = meals.Meal.fromFirestore(mealDoc);
    _mealsCache[mealId] = meal;
    return meal;
  }

  // Batch processing ottimizzato
  Future<void> _processBatchQueue() async {
    if (_isBatchProcessing) return;
    _isBatchProcessing = true;

    try {
      while (_batchQueue.isNotEmpty) {
        final batch = _firestore.batch();
        final operations = _batchQueue.take(500).toList(); // Limite di Firestore
        _batchQueue.removeRange(0, operations.length);

        for (final operation in operations) {
          await operation();
        }

        await batch.commit();
      }
    } finally {
      _isBatchProcessing = false;
    }
  }

  // Ottimizzazione delle operazioni di scrittura
  Future<void> addFoodToMeal({
    required String userId,
    required String mealId,
    required macros.Food food,
    required double quantity,
  }) async {
    final batch = _firestore.batch();
    final meal = await getMealById(userId, mealId);

    if (meal == null) throw Exception('Meal not found');

    final myFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();

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
    );

    _foodsCache[myFood.id!] = myFood;

    batch.set(myFoodRef, myFood.toMap());
    await batch.commit();

    // Aggiorna i totali in background
    _batchQueue.add(() => updateMealAndDailyStats(userId, mealId, myFood, isAdding: true));
    _processBatchQueue();
  }

  // Stream ottimizzato con cache
  Stream<List<meals.Meal>> getUserMealsByDate({required String userId, required DateTime date}) {
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
          return snapshot.docs.map((doc) {
            final meal = meals.Meal.fromFirestore(doc);
            _mealsCache[meal.id!] = meal;
            return meal;
          }).toList();
        });
  }

  // Ottimizzazione del calcolo dei nutrienti
  Future<Map<String, double>> getTotalNutrientsForMeal(String userId, String mealId) async {
    final foods = await getFoodsForMeals(userId: userId, mealId: mealId);

    return foods.fold<Map<String, double>>({'carbs': 0, 'proteins': 0, 'fats': 0, 'calories': 0}, (
      totals,
      food,
    ) {
      totals['carbs'] = (totals['carbs'] ?? 0) + food.carbs;
      totals['proteins'] = (totals['proteins'] ?? 0) + food.protein;
      totals['fats'] = (totals['fats'] ?? 0) + food.fat;
      totals['calories'] = (totals['calories'] ?? 0) + food.kcal;
      return totals;
    });
  }

  // Gestione efficiente della memoria
  void _clearCache() {
    _mealsCache.clear();
    _dailyStatsCache.clear();
    _foodsCache.clear();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _mealsStreamController.close();
    _dailyStatsStreamController.close();
    _clearCache();
    super.dispose();
  }

  // Metodi per la gestione delle statistiche giornaliere
  Future<void> createDailyStatsIfNotExist(String userId, DateTime date) async {
    final dailyStatsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc(date.toIso8601String().split('T')[0]);

    final dailyStatsDoc = await dailyStatsRef.get();
    if (!dailyStatsDoc.exists) {
      final dailyStats = meals.DailyStats(
        id: dailyStatsRef.id,
        userId: userId,
        date: date,
        totalCalories: 0,
        totalCarbs: 0,
        totalFat: 0,
        totalProtein: 0,
      );
      await dailyStatsRef.set(dailyStats.toMap());
      if (dailyStats.id != null) {
        _dailyStatsCache[dailyStats.id!] = dailyStats;
      }
    }
  }

  Future<void> createMealsIfNotExist(String userId, DateTime date) async {
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final dailyStatsId = date.toIso8601String().split('T')[0];

    for (final mealType in mealTypes) {
      final mealRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc('${dailyStatsId}_$mealType');

      final mealDoc = await mealRef.get();
      if (!mealDoc.exists) {
        final meal = meals.Meal(
          id: mealRef.id,
          userId: userId,
          dailyStatsId: dailyStatsId,
          date: date,
          mealType: mealType,
        );
        await mealRef.set(meal.toMap());
        _mealsCache[meal.id!] = meal;
      }
    }
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
        .map((snapshot) => snapshot.docs.map((doc) => macros.Food.fromFirestore(doc)).toList());
  }

  Future<List<macros.Food>> getFoodsForMeals({
    required String userId,
    required String mealId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .where('mealId', isEqualTo: mealId)
        .get();

    return snapshot.docs.map((doc) => macros.Food.fromFirestore(doc)).toList();
  }

  Future<void> removeFoodFromMeal({
    required String userId,
    required String mealId,
    required String myFoodId,
  }) async {
    final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);

    final foodDoc = await foodRef.get();
    if (!foodDoc.exists) return;

    final food = macros.Food.fromFirestore(foodDoc);
    await foodRef.delete();
    _foodsCache.remove(myFoodId);

    // Aggiorna i totali in background
    _batchQueue.add(() => updateMealAndDailyStats(userId, mealId, food, isAdding: false));
    _processBatchQueue();
  }

  Future<void> updateMealAndDailyStats(
    String userId,
    String mealId,
    macros.Food food, {
    required bool isAdding,
  }) async {
    final meal = await getMealById(userId, mealId);
    if (meal == null) return;

    final multiplier = isAdding ? 1 : -1;
    meal.totalCalories += food.kcal * multiplier;
    meal.totalCarbs += food.carbs * multiplier;
    meal.totalFat += food.fat * multiplier;
    meal.totalProtein += food.protein * multiplier;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId)
        .update(meal.toMap());

    _mealsCache[mealId] = meal;

    final dailyStatsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc(meal.dailyStatsId);

    final dailyStatsDoc = await dailyStatsRef.get();
    if (!dailyStatsDoc.exists) return;

    final dailyStats = meals.DailyStats.fromFirestore(dailyStatsDoc);
    dailyStats.totalCalories += food.kcal * multiplier;
    dailyStats.totalCarbs += food.carbs * multiplier;
    dailyStats.totalFat += food.fat * multiplier;
    dailyStats.totalProtein += food.protein * multiplier;

    await dailyStatsRef.update(dailyStats.toMap());
    if (dailyStats.id != null) {
      _dailyStatsCache[dailyStats.id!] = dailyStats;
    }
    notifyListeners();
  }

  Stream<meals.DailyStats> getDailyStatsByDateStream(String userId, DateTime date) {
    final dailyStatsId = date.toIso8601String().split('T')[0];
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc(dailyStatsId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? meals.DailyStats.fromFirestore(doc)
              : meals.DailyStats(
                  id: dailyStatsId,
                  userId: userId,
                  date: date,
                  totalCalories: 0,
                  totalCarbs: 0,
                  totalFat: 0,
                  totalProtein: 0,
                ),
        );
  }

  Future<macros.Food?> getMyFoodById(String userId, String foodId) async {
    if (_foodsCache.containsKey(foodId)) {
      return _foodsCache[foodId];
    }

    final foodDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('myfoods')
        .doc(foodId)
        .get();

    if (!foodDoc.exists) return null;

    final food = macros.Food.fromFirestore(foodDoc);
    _foodsCache[foodId] = food;
    return food;
  }

  Future<void> updateMyFood({
    required String userId,
    required String myFoodId,
    required macros.Food updatedFood,
  }) async {
    final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);

    await foodRef.update(updatedFood.toMap());
    _foodsCache[myFoodId] = updatedFood;
    notifyListeners();
  }

  Future<void> addFoodToFavoriteMeal({
    required String userId,
    required String mealId,
    required macros.Food food,
  }) async {
    final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();

    final myFood = food.copyWith(id: foodRef.id, mealId: mealId);

    await foodRef.set(myFood.toMap());
    _foodsCache[myFood.id!] = myFood;
    notifyListeners();
  }

  Future<void> removeFoodFromFavoriteMeal({
    required String userId,
    required String mealId,
    required String myFoodId,
  }) async {
    final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(myFoodId);

    await foodRef.delete();
    _foodsCache.remove(myFoodId);
    notifyListeners();
  }

  Future<List<meals.Meal>> getFavoriteMeals(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('isFavorite', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
  }

  Future<void> saveMealAsFavorite(
    String userId,
    String mealId, {
    required String favoriteName,
    required String dailyStatsId,
  }) async {
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);

    await mealRef.update({'isFavorite': true, 'favoriteName': favoriteName});

    final meal = _mealsCache[mealId];
    if (meal != null) {
      meal.isFavorite = true;
      meal.favoriteName = favoriteName;
      notifyListeners();
    }
  }

  Future<void> deleteFavoriteMeal(String userId, String mealId) async {
    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc(mealId);

    await mealRef.delete();
    _mealsCache.remove(mealId);
    notifyListeners();
  }

  Future<List<meals.FavoriteDay>> getFavoriteDays(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDays')
        .get();

    return snapshot.docs.map((doc) => meals.FavoriteDay.fromFirestore(doc)).toList();
  }

  Future<void> saveDayAsFavorite(
    String userId,
    DateTime date, {
    required String favoriteName,
  }) async {
    final dailyStatsId = date.toIso8601String().split('T')[0];

    final favoriteDay = meals.FavoriteDay(
      id: dailyStatsId,
      userId: userId,
      date: date,
      favoriteName: favoriteName,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDays')
        .doc(favoriteDay.id)
        .set(favoriteDay.toMap());
  }

  Future<void> deleteFavoriteDay(String userId, String dayId) async {
    await _firestore.collection('users').doc(userId).collection('favoriteDays').doc(dayId).delete();
  }

  Future<void> applyFavoriteDayToCurrent(
    String userId,
    String favoriteDayId,
    DateTime targetDate,
  ) async {
    final favoriteDayDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDays')
        .doc(favoriteDayId)
        .get();

    if (!favoriteDayDoc.exists) return;

    final favoriteDay = meals.FavoriteDay.fromFirestore(favoriteDayDoc);
    final batch = _firestore.batch();

    await createDailyStatsIfNotExist(userId, targetDate);
    await createMealsIfNotExist(userId, targetDate);

    final mealsList = await _getMealsByDate(userId, favoriteDay.date);
    for (final meal in mealsList) {
      final foods = await getFoodsForMeals(userId: userId, mealId: meal.id!);
      for (final food in foods) {
        await addFoodToMeal(
          userId: userId,
          mealId: '${targetDate.toIso8601String().split('T')[0]}_${meal.mealType}',
          food: food,
          quantity: food.quantity ?? 100,
        );
      }
    }

    await batch.commit();
  }

  Future<void> createMealsFromMealIdsBatch(
    String userId,
    DateTime date,
    List<String> mealIds,
    WriteBatch batch,
  ) async {
    final dailyStatsId = date.toIso8601String().split('T')[0];

    for (final mealId in mealIds) {
      final originalMeal = await getMealById(userId, mealId);
      if (originalMeal == null) continue;

      final newMealRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc('${dailyStatsId}_${originalMeal.mealType}');

      final newMeal = originalMeal.copyWith(
        id: newMealRef.id,
        dailyStatsId: dailyStatsId,
        date: date,
      );

      batch.set(newMealRef, newMeal.toMap());
      if (newMeal.id != null) {
        _mealsCache[newMeal.id!] = newMeal;
      }

      final foods = await getFoodsForMeals(userId: userId, mealId: mealId);
      for (final food in foods) {
        final newFoodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc();

        final newFood = food.copyWith(id: newFoodRef.id, mealId: newMealRef.id);

        batch.set(newFoodRef, newFood.toMap());
        if (newFood.id != null) {
          _foodsCache[newFood.id!] = newFood;
        }
      }
    }
  }

  Future<List<meals.Meal>> _getMealsByDate(String userId, DateTime date) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day))
        .where('date', isLessThan: DateTime(date.year, date.month, date.day + 1))
        .get();

    return snapshot.docs.map((doc) => meals.Meal.fromFirestore(doc)).toList();
  }

  Future<void> copyMeal({
    required String userId,
    required String sourceMealId,
    required String targetMealId,
  }) async {
    final sourceMeal = await getMealById(userId, sourceMealId);
    if (sourceMeal == null) return;

    final foods = await getFoodsForMeals(userId: userId, mealId: sourceMealId);
    for (final food in foods) {
      await addFoodToMeal(
        userId: userId,
        mealId: targetMealId,
        food: food,
        quantity: food.quantity ?? 100,
      );
    }
  }

  Future<void> moveFoods({
    required String userId,
    required List<String> foodIds,
    required String targetMealId,
  }) async {
    final batch = _firestore.batch();

    for (final foodId in foodIds) {
      final foodRef = _firestore.collection('users').doc(userId).collection('myfoods').doc(foodId);

      final foodDoc = await foodRef.get();
      if (foodDoc.exists) {
        final food = macros.Food.fromFirestore(foodDoc);
        final updatedFood = food.copyWith(mealId: targetMealId);
        batch.update(foodRef, updatedFood.toMap());
      }
    }

    await batch.commit();
    notifyListeners();
  }

  Future<void> applyFavoriteMealToCurrent(
    String userId,
    String favoriteMealId,
    String currentMealId,
  ) async {
    final favoriteMeal = await getMealById(userId, favoriteMealId);
    if (favoriteMeal == null) return;

    final foods = await getFoodsForMeals(userId: userId, mealId: favoriteMealId);
    for (final food in foods) {
      await addFoodToMeal(
        userId: userId,
        mealId: currentMealId,
        food: food,
        quantity: food.quantity ?? 100,
      );
    }
  }

  Future<String> createSnack({
    required String userId,
    required String dailyStatsId,
    required DateTime date,
  }) async {
    final snackMeal = meals.Meal(
      userId: userId,
      dailyStatsId: dailyStatsId,
      date: date,
      mealType: 'Snack',
    );

    final mealRef = _firestore.collection('users').doc(userId).collection('meals').doc();

    snackMeal.id = mealRef.id;
    await mealRef.set(snackMeal.toMap());

    if (snackMeal.id != null) {
      _mealsCache[snackMeal.id!] = snackMeal;
    }

    return mealRef.id;
  }
}
