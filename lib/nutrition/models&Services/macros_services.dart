import 'dart:async';
import 'dart:convert'; // Aggiungi questa importazione per la decodifica JSON
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:http/http.dart' as http; // Aggiungi questa importazione
import 'macros_model.dart';

final macrosServiceProvider = Provider<MacrosService>((ref) {
  return MacrosService(ref, FirebaseFirestore.instance);
});

class MacrosService {
  final ProviderRef ref;
  final FirebaseFirestore _firestore;
  final _foodsStreamController = BehaviorSubject<List<Food>>.seeded([]);
  final _searchResultsStreamController = BehaviorSubject<List<Food>>.seeded([]);
  final Map<String, List<String>> _suggestionsCache =
      {}; // Cache per i suggerimenti
  final Map<String, List<Food>> _foodsCache =
      {}; // Cache per i risultati dei cibi
  String _searchQuery = '';
  StreamSubscription? _foodsChangesSubscription;

  MacrosService(this.ref, this._firestore) {
    _initializeFoodsStream();
    _setupOpenFoodFacts();
  }

  void _setupOpenFoodFacts() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'alphaness',
      url: 'https://alphaness-322423.web.app/',
    );
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ITALIAN
    ];
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

    // Combina i risultati di Firestore e OpenFoodFacts
    final firestoreResults = await _searchResultsStreamController.stream.first;
    final openFoodFactsResults = await searchOpenFoodFacts(query);

    final combinedResults = [...firestoreResults, ...openFoodFactsResults];
    _foodsCache[query] = combinedResults; // Cache dei risultati

    yield combinedResults;
  }

  Future<List<Food>> searchOpenFoodFacts(String query) async {
    if (_foodsCache.containsKey(query)) {
      return _foodsCache[query]!;
    }

    final ProductSearchQueryConfiguration configuration =
        ProductSearchQueryConfiguration(
      parametersList: <Parameter>[
        SearchTerms(terms: [query]),
      ],
      fields: [ProductField.ALL],
      language: OpenFoodFactsLanguage.ITALIAN,
      version: ProductQueryVersion.v3,
    );

    final SearchResult result = await OpenFoodAPIClient.searchProducts(
      null,
      configuration,
    );

    if (result.products != null) {
      final foods = result.products!.map((product) {
        return Food(
          id: product.barcode ?? '',
          name: product.productName ?? 'Unknown',
          kcal: product.nutriments
                  ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ??
              0.0,
          carbs: product.nutriments
                  ?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ??
              0.0,
          fat: product.nutriments
                  ?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ??
              0.0,
          protein: product.nutriments
                  ?.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ??
              0.0,
        );
      }).toList();
      _foodsCache[query] = foods; // Cache dei risultati
      return foods;
    } else {
      return [];
    }
  }

  Future<List<String>> getSuggestions(String query) async {
    if (_suggestionsCache.containsKey(query)) {
      return _suggestionsCache[query]!;
    }

    final Map<String, String> queryParameters = <String, String>{
      'tagtype': 'categories',
      'lc': OpenFoodFactsLanguage.ITALIAN.offTag,
      'string': query,
      'limit': '25',
    };

    final Uri uri = Uri(
      scheme: 'https',
      host: 'world.openfoodfacts.org',
      path: '/api/v3/taxonomy_suggestions',
      queryParameters: queryParameters,
    );

    debugPrint('Requesting suggestions from: $uri');

    try {
      final http.Response response = await http.get(uri);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load suggestions');
      }

      final Map<String, dynamic> map = json.decode(response.body);
      final List<String> result = <String>[];
      if (map['suggestions'] != null) {
        for (dynamic value in map['suggestions']) {
          result.add(value.toString());
        }
      }
      _suggestionsCache[query] = result; // Cache dei suggerimenti
      return result;
    } catch (e) {
      debugPrint('getSuggestions: Failed to load suggestions: $e');
      throw Exception('Failed to load suggestions');
    }
  }

  Stream<List<Food>> getFoods() {
    return _foodsStreamController.stream.doOnData((foods) {
      debugPrint('Emitted foods: $foods');
    });
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
    final foodRef = _firestore.collection('foods').doc();
    food.id = foodRef.id;
    await foodRef.set(food.toMap());
  }

  Future<void> updateFood(String foodId, Food updatedFood) async {
    await _firestore
        .collection('foods')
        .doc(foodId)
        .update(updatedFood.toMap());
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
