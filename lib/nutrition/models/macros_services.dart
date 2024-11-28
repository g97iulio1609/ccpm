import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'macros_model.dart';

final macrosServiceProvider = Provider<MacrosService>((ref) {
  return MacrosService(ref, FirebaseFirestore.instance);
});

class MacrosService {
  final Ref ref;
  final FirebaseFirestore _firestore;

  // Cache ottimizzata
  final _foodsCache = <String, Food>{};
  final _userFoodsCache = <String, Map<String, Food>>{};

  // Stream controllers ottimizzati
  final _foodsStreamController = BehaviorSubject<List<Food>>.seeded([]);
  final _searchResultsStreamController = BehaviorSubject<List<Food>>.seeded([]);

  // Gestione delle sottoscrizioni
  final _subscriptions = <StreamSubscription>[];

  // Gestione della ricerca
  String _searchQuery = '';
  Timer? _searchDebouncer;

  // Batch operations
  final _batchQueue = <Future Function()>[];
  bool _isBatchProcessing = false;

  MacrosService(this.ref, this._firestore) {
    _initializeService();
  }

  void _initializeService() {
    _subscriptions.add(
        _firestore.collection('foods').snapshots().listen(_handleFoodsUpdate));
  }

  void _handleFoodsUpdate(QuerySnapshot snapshot) {
    final foods = snapshot.docs.map((doc) {
      final food = Food.fromFirestore(doc);
      _foodsCache[food.id!] = food;
      return food;
    }).toList();
    _foodsStreamController.add(foods);
  }

  void setSearchQuery(String query) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query.trim().toLowerCase();
      _searchFoods();
    });
  }

  Future<void> _searchFoods() async {
    if (_searchQuery.isEmpty) {
      _searchResultsStreamController.add(_foodsCache.values.toList());
      return;
    }

    try {
      // Prima cerca nella cache
      final cachedResults = _foodsCache.values
          .where((food) => food.name.toLowerCase().contains(_searchQuery))
          .toList();

      if (cachedResults.isNotEmpty) {
        _searchResultsStreamController.add(cachedResults);
        return;
      }

      // Se non trova risultati nella cache, cerca su Firestore
      final firestoreResults = await _firestore
          .collection('foods')
          .orderBy('name')
          .startAt([_searchQuery])
          .endAt([_searchQuery + '\uf8ff'])
          .limit(10)
          .get();

      final foods = firestoreResults.docs.map((doc) {
        final food = Food.fromFirestore(doc);
        _foodsCache[food.id!] = food;
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

  // Ottimizzazione delle query con cache
  Future<Food?> getFoodById(String foodId) async {
    if (_foodsCache.containsKey(foodId)) {
      return _foodsCache[foodId];
    }

    final foodDoc = await _firestore.collection('foods').doc(foodId).get();
    if (!foodDoc.exists) return null;

    final food = Food.fromFirestore(foodDoc);
    _foodsCache[foodId] = food;
    return food;
  }

  // Batch processing ottimizzato
  Future<void> _processBatchQueue() async {
    if (_isBatchProcessing) return;
    _isBatchProcessing = true;

    try {
      while (_batchQueue.isNotEmpty) {
        final batch = _firestore.batch();
        final operations =
            _batchQueue.take(500).toList(); // Limite di Firestore
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
  Future<void> addFood(Food food) async {
    final batch = _firestore.batch();
    final foodRef = _firestore.collection('foods').doc();
    food.name = food.name.toLowerCase();

    _foodsCache[food.id!] = food;

    batch.set(foodRef, food.toMap());
    await batch.commit();
  }

  Future<void> addFoodToUser({
    required String userId,
    required String foodId,
    required double quantity,
    required DateTime date,
  }) async {
    final foodData = await getFoodById(foodId);
    if (foodData == null) return;

    final batch = _firestore.batch();
    final userFoodRef =
        _firestore.collection('users').doc(userId).collection('foods').doc();

    final userFoodData = {
      'foodId': foodId,
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      ...foodData.toMap(),
    };

    if (!_userFoodsCache.containsKey(userId)) {
      _userFoodsCache[userId] = {};
    }
    _userFoodsCache[userId]![userFoodRef.id] = Food.fromMap(userFoodData);

    batch.set(userFoodRef, userFoodData);
    await batch.commit();
  }

  // Stream ottimizzato con cache
  Stream<List<Food>> getUserFoods({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      final foods = snapshot.docs.map((doc) {
        final food = Food.fromFirestore(doc);
        if (!_userFoodsCache.containsKey(userId)) {
          _userFoodsCache[userId] = {};
        }
        _userFoodsCache[userId]![food.id!] = food;
        return food;
      }).toList();
      return foods;
    });
  }

  // Gestione efficiente della memoria
  void _clearCache() {
    _foodsCache.clear();
    _userFoodsCache.clear();
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _searchDebouncer?.cancel();
    _foodsStreamController.close();
    _searchResultsStreamController.close();
    _clearCache();
  }
}
