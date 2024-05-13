import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'macros_model.dart';

final macrosServiceProvider = Provider<MacrosService>((ref) {
  return MacrosService(ref, FirebaseFirestore.instance);
});

class MacrosService {
  final ProviderRef ref;
  final FirebaseFirestore _firestore;
  final _foodsStreamController = BehaviorSubject<List<Food>>();
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

  void searchFoods(String query) {
    _searchQuery = query;
    final foods = _foodsStreamController.value;
    _foodsStreamController.add(_filterFoods(foods));
  }

  Stream<List<Food>> getFoods() {
    return _foodsStreamController.stream;
  }

  Future<Food?> getFoodById(String foodId) async {
    final foodDoc = await _firestore.collection('foods').doc(foodId).get();
    if (foodDoc.exists) {
      return Food.fromFirestore(foodDoc);
    } else {
      return null;
    }
  }

  Future<void> addFood(Food food) async {
    await _firestore.collection('foods').add(food.toMap());
  }

  Future<void> updateFood(String foodId, Food updatedFood) async {
    await _firestore.collection('foods').doc(foodId).update(updatedFood.toMap());
  }

  Future<void> deleteFood(String foodId) async {
    await _firestore.collection('foods').doc(foodId).delete();
  }

  Future<void> addFoodToUser({
    required String userId,
    required String foodId,
    required double quantity,
    required DateTime date,
  }) async {
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
    }
  }

  Future<void> updateUserFood({
    required String userId,
    required String userFoodId,
    required double quantity,
    required DateTime date,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(userFoodId)
        .update({
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
    });
  }

  Future<void> deleteUserFood({
    required String userId,
    required String userFoodId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(userFoodId)
        .delete();
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
    await batch.commit();
  }

  Future<void> exportFoods() async {
    final snapshot = await _firestore.collection('foods').get();
    final foodsData = snapshot.docs.map((doc) => doc.data()).toList();
    // Perform the export operation using the foodsData
    // For example, you can convert it to JSON and save it to a file or send it to an API
  }
}