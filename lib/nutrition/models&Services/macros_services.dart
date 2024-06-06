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
      _foodsStreamController.add(foods);
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _searchFoods();
  }

  Future<void> _searchFoods() async {
    try {
      final firestoreResults = await _firestore
          .collection('foods')
          .orderBy('name')
          .startAt([_searchQuery])
          .endAt([_searchQuery + '\uf8ff'])
          .limit(10)
          .get();

      final foods = firestoreResults.docs.map((doc) {
        final food = Food.fromFirestore(doc);
        return food;
      }).toList();
      _searchResultsStreamController.add(foods);
    } catch (e) {
      _searchResultsStreamController.addError(e);
    }
  }

  Stream<List<Food>> searchFoods(String query) {
    setSearchQuery(query);
    return _searchResultsStreamController.stream;
  }

  Future<Food?> getFoodById(String foodId) async {
    final foodDoc = await _firestore.collection('foods').doc(foodId).get();
    if (foodDoc.exists) {
      return Food.fromFirestore(foodDoc);
    }
    return null;
  }

  Future<void> addFood(Food food) async {
    final batch = _firestore.batch();
    final foodRef = _firestore.collection('foods').doc(food.id);
    food.name = food.name.toLowerCase();
    batch.set(foodRef, food.toMap());
    await batch.commit();
  }

  Future<void> updateFood(String foodId, Food updatedFood) async {
    final batch = _firestore.batch();
    final foodRef = _firestore.collection('foods').doc(foodId);
    updatedFood.name = updatedFood.name.toLowerCase();
    batch.update(foodRef, updatedFood.toMap());
    await batch.commit();
  }

  Future<void> deleteFood(String foodId) async {
    final batch = _firestore.batch();
    final foodRef = _firestore.collection('foods').doc(foodId);
    batch.delete(foodRef);
    await batch.commit();
  }

  Future<void> addFoodToUser({
    required String userId,
    required String foodId,
    required double quantity,
    required DateTime date,
  }) async {
    final foodData = await getFoodById(foodId);
    if (foodData != null) {
      final batch = _firestore.batch();
      final userFoodRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('foods')
          .doc();
      final userFoodData = {
        'foodId': foodId,
        'quantity': quantity,
        'date': Timestamp.fromDate(date),
        'userId': userId,
        ...foodData.toMap(),
      };
      batch.set(userFoodRef, userFoodData);
      await batch.commit();
    }
  }

  Future<void> updateUserFood({
    required String userId,
    required String userFoodId,
    required double quantity,
    required DateTime date,
  }) async {
    final batch = _firestore.batch();
    final userFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(userFoodId);
    batch.update(userFoodRef, {
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
    });
    await batch.commit();
  }

  Future<void> deleteUserFood({
    required String userId,
    required String userFoodId,
  }) async {
    final batch = _firestore.batch();
    final userFoodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(userFoodId);
    batch.delete(userFoodRef);
    await batch.commit();
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
      foodData['name'] = foodData['name'].toString().toLowerCase();
      batch.set(foodRef, foodData);
    }
    await batch.commit();
  }

  Future<void> exportFoods() async {
    final snapshot = await _firestore.collection('foods').get();
    final foodsData = snapshot.docs.map((doc) => doc.data()).toList();
    // Perform the export operation using the foodsData
    // For example, you can convert it to JSON and save it to a file or send it to an API
  }
}