import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'macros_model.dart';

final macrosServiceProvider = Provider<MacrosService>((ref) {
  return MacrosService(ref, FirebaseFirestore.instance);
});

class MacrosService {
  final ProviderRef ref;
  final FirebaseFirestore _firestore;
  final _foodsStreamController = BehaviorSubject<List<Food>>.seeded([]);
  final _searchResultsStreamController = BehaviorSubject<List<Food>>.seeded([]);
  final Map<String, List<Food>> _foodsCache = {}; // Cache per i risultati dei cibi
  String _searchQuery = '';
  StreamSubscription? _foodsChangesSubscription;

  MacrosService(this.ref, this._firestore) {
    _initializeFoodsStream();
  }

  void _initializeFoodsStream() {
    _foodsChangesSubscription?.cancel();
    _foodsChangesSubscription =
        _firestore.collection('foods').snapshots().listen((snapshot) {
      final foods =
          snapshot.docs.map((doc) => Food.fromFirestore(doc)).toList();
      _foodsStreamController.add(_filterFoods(foods));
    });
  }

  List<Food> _filterFoods(List<Food> foods) {
    if (_searchQuery.isEmpty) {
      return foods;
    } else {
      final lowercaseQuery = _searchQuery.toLowerCase();
      return foods
          .where((food) => food.name.toLowerCase().contains(lowercaseQuery))
          .toList();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    final foods = _foodsStreamController.valueOrNull ?? [];
    _searchResultsStreamController.add(_filterFoods(foods));
  }

  Stream<List<Food>> searchFoods(String query) async* {
    setSearchQuery(query);

    // Usa il cache per migliorare le prestazioni
    if (_foodsCache.containsKey(query)) {
      yield _foodsCache[query]!;
      return;
    }

    // Cerca i cibi su Firestore
    final firestoreResults = await _searchResultsStreamController.stream.first;
    _foodsCache[query] = firestoreResults;

    yield firestoreResults;
  }

  Future<Food?> getFoodById(String foodId) async {
    try {
      final foodDoc = await _firestore.collection('foods').doc(foodId).get();
      if (foodDoc.exists) {
        return Food.fromFirestore(foodDoc);
      } else {
        debugPrint('getFoodById: Food not found in Firestore for ID = $foodId');
        return null;
      }
    } catch (e) {
      debugPrint('getFoodById: Error fetching food by ID = $foodId: $e');
      return null;
    }
  }

  Future<void> addFood(Food food) async {
    try {
      final foodRef = _firestore.collection('foods').doc(food.id);
      await foodRef.set(food.toMap());
      debugPrint('addFood: Food added with ID = ${food.id}');
    } catch (e) {
      debugPrint('addFood: Error adding food: $e');
    }
  }

  Future<void> updateFood(String foodId, Food updatedFood) async {
    try {
      await _firestore.collection('foods').doc(foodId).update(updatedFood.toMap());
      debugPrint('updateFood: Food updated with ID = $foodId');
    } catch (e) {
      debugPrint('updateFood: Error updating food with ID = $foodId: $e');
    }
  }

  Future<void> deleteFood(String foodId) async {
    try {
      await _firestore.collection('foods').doc(foodId).delete();
      debugPrint('deleteFood: Food deleted with ID = $foodId');
    } catch (e) {
      debugPrint('deleteFood: Error deleting food with ID = $foodId: $e');
    }
  }

  Future<void> addFoodToUser({
    required String userId,
    required String foodId,
    required double quantity,
    required DateTime date,
  }) async {
    try {
      final foodData = await getFoodById(foodId);
      if (foodData != null) {
        final userFoodData = {
          'foodId': foodId,
          'quantity': quantity,
          'date': Timestamp.fromDate(date),
          'userId': userId,
          ...foodData.toMap(),
        };
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('foods')
            .add(userFoodData);
        debugPrint('addFoodToUser: Food added to user with ID = $userId');
      }
    } catch (e) {
      debugPrint('addFoodToUser: Error adding food to user with ID = $userId: $e');
    }
  }

  Future<void> updateUserFood({
    required String userId,
    required String userFoodId,
    required double quantity,
    required DateTime date,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('foods')
          .doc(userFoodId)
          .update({
        'quantity': quantity,
        'date': Timestamp.fromDate(date),
      });
      debugPrint('updateUserFood: Food updated for user with ID = $userId');
    } catch (e) {
      debugPrint('updateUserFood: Error updating food for user with ID = $userId: $e');
    }
  }

  Future<void> deleteUserFood({
    required String userId,
    required String userFoodId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('foods')
          .doc(userFoodId)
          .delete();
      debugPrint('deleteUserFood: Food deleted for user with ID = $userId');
    } catch (e) {
      debugPrint('deleteUserFood: Error deleting food for user with ID = $userId: $e');
    }
  }

  Stream<List<Food>> getUserFoods({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Food.fromMap(data);
      }).toList();
    });
  }

  Future<void> importFoods(List<Map<String, dynamic>> foodsData) async {
    final batch = _firestore.batch();
    for (final foodData in foodsData) {
      final foodRef = _firestore.collection('foods').doc();
      batch.set(foodRef, foodData);
    }
    try {
      await batch.commit();
      debugPrint('importFoods: Foods imported successfully');
    } catch (e) {
      debugPrint('importFoods: Error importing foods: $e');
    }
  }

  Future<void> exportFoods() async {
    try {
      final snapshot = await _firestore.collection('foods').get();
      final foodsData = snapshot.docs.map((doc) => doc.data()).toList();
      // Perform the export operation using the foodsData
      // For example, you can convert it to JSON and save it to a file or send it to an API
      debugPrint('exportFoods: Foods exported successfully');
    } catch (e) {
      debugPrint('exportFoods: Error exporting foods: $e');
    }
  }
}
