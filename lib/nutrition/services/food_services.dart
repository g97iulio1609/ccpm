import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'dart:async';

class FoodService {
  final FirebaseFirestore _firestore;
  bool _isImporting = false; // Stato per tracciare l'importazione
  final _importProgressController =
      StreamController<Map<String, int>>.broadcast();

  Stream<Map<String, int>> get importProgressStream =>
      _importProgressController.stream;

  FoodService(this._firestore) {
    // Imposta l'User-Agent per OpenFoodFacts
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'alphanessone',
      url: 'https://alphaness-322423.web.app/',
      version: '1.0.0',
    );
  }

  Future<void> importFoods({
    int pages = 10,
    List<String> mainCategories = const [
      'pasta',
      'meat',
      'fish',
      'legumes',
      'milk',
      'dairy',
      'spices',
      'beverages',
    ],
    List<String> subCategories = const [
      'grains',
      'cereals',
      'bread',
      'cereal',
      'biscuits'
          'eggs',
      'fresh-fruits',
      'fresh-vegetables',
      'frozen-fruits',
      'frozen-vegetables',
      'dried-fruits',
      'soft-drinks',
      'juices',
      'alcoholic-beverages',
      'tea',
      'coffee',
      'cooking-oils',
      'margarine',
      'animal-fats',
      'cookies',
      'cakes',
      'chocolate',
      'chips',
      'herbs',
      'sauces',
      'dressings',
      'ready-to-eat-meals',
      'canned-foods',
      'frozen-meals',
      'bakery-products',
      'pastries',
      'muffins',
      'nuts',
      'seeds',
      'shellfish',
      'salmon',
      'tuna',
      'honey',
      'maple-syrup',
      'sugar',
      'baby-formula',
      'baby-snacks',
      'baby-purees',
      'supplements',
      'protein-bars',
      'health-drinks',
    ],
    OpenFoodFactsLanguage language = OpenFoodFactsLanguage.ITALIAN,
    OpenFoodFactsCountry country = OpenFoodFactsCountry.ITALY,
  }) async {
    _isImporting = true; // Impostare lo stato di importazione a true

    await _importCategoryFoods(mainCategories, pages, language, country);
    await _importCategoryFoods(subCategories, pages, language, country);

    _isImporting = false; // Reimpostare lo stato di importazione a false
    _importProgressController.add({});
  }

  Future<void> _importCategoryFoods(
    List<String> categories,
    int pages,
    OpenFoodFactsLanguage language,
    OpenFoodFactsCountry country,
  ) async {
    for (final category in categories) {
      if (!_isImporting) {
        break; // Fermare l'importazione se _isImporting è false
      }
      final lastPage = await _getLastImportedPage(category);
      int importedProducts = 0; // Numero di prodotti importati per la categoria

      for (int page = lastPage + 1; page <= lastPage + pages; page++) {
        if (!_isImporting) {
          break; // Fermare l'importazione se _isImporting è false
        }
        // importing page (debug removed)
        final configuration = ProductSearchQueryConfiguration(
          parametersList: <Parameter>[
            TagFilter.fromType(
              tagFilterType: TagFilterType.CATEGORIES,
              tagName: category,
            ),
            TagFilter.fromType(
              tagFilterType: TagFilterType.COUNTRIES,
              tagName: country.offTag,
            ),
            const SortBy(option: SortOption.POPULARITY),
            const PageSize(size: 100),
            PageNumber(page: page),
          ],
          fields: [ProductField.ALL],
          language: language,
          version: ProductQueryVersion.v3,
        );

        try {
          importedProducts += await _importWithRetry(
            configuration,
            category,
            page,
          );
          _importProgressController.add({
            category: importedProducts,
          }); // Aggiorna il progresso
        } catch (e, st) {
          // Log import failure for the category/page so it can be retried later
          // ignore: avoid_print
          print('Failed importing category "$category" page $page: $e\n$st');
        }

        await Future.delayed(
          const Duration(seconds: 60),
        ); // Aspetta 60 secondi tra le pagine
      }
    }
  }

  Future<int> getTotalFoodsCount() async {
    final querySnapshot = await _firestore.collection('foods').get();
    return querySnapshot.size;
  }

  Future<int> _importWithRetry(
    ProductSearchQueryConfiguration configuration,
    String category,
    int page, {
    int retryCount = 3,
  }) async {
    int attempts = 0;
    while (attempts < retryCount) {
      if (!_isImporting) {
        return 0; // Fermare l'importazione se _isImporting è false
      }
      try {
        SearchResult result = await OpenFoodAPIClient.searchProducts(
          null,
          configuration,
        );

        if (result.products != null && result.products!.isNotEmpty) {
          for (var product in result.products!) {
            await _importOrUpdateProduct(product, category);
          }
          await _updateLastImportedPage(
            category,
            page,
          ); // Update the last imported page
          return result
              .products!
              .length; // Ritorna il numero di prodotti importati
        } else {
          break; // Exit the loop if no products are found
        }
      } catch (e) {
        attempts++;
        if (attempts < retryCount) {
          final waitTimeMinutes = (5 * attempts).clamp(5, 30);
          final waitTime = Duration(minutes: waitTimeMinutes);
          // retry info (debug removed)
          await Future.delayed(waitTime); // Delay with exponential backoff
        } else {
          // retries exceeded (debug removed)
          rethrow; // Rethrow the exception if max retries reached
        }
      }
    }
    return 0; // Ritorna 0 se nessun prodotto è stato importato
  }

  Future<int> _getLastImportedPage(String category) async {
    final doc = await _firestore
        .collection('import_status')
        .doc(category)
        .get();
    if (doc.exists && doc.data() != null && doc.data()!['lastPage'] != null) {
      return doc.data()!['lastPage'];
    }
    return 0; // Start from page 0 if no data is found
  }

  Future<void> _updateLastImportedPage(String category, int page) async {
    await _firestore.collection('import_status').doc(category).set({
      'lastPage': page,
    });
  }

  Future<void> _importOrUpdateProduct(Product product, String category) async {
    try {
      var doc = await _firestore.collection('foods').doc(product.barcode).get();
      if (!doc.exists) {
        await _firestore
            .collection('foods')
            .doc(product.barcode)
            .set(_productToMap(product, category));
      } else {
        // skipping existing product (debug removed)
      }
    } catch (e, st) {
      // Log product import errors to help debugging
      // ignore: avoid_print
      print('Error importing product ${product.barcode}: $e\n$st');
    }
  }

  Map<String, dynamic> _productToMap(Product product, String category) {
    return {
      'id': product.barcode,
      'name': product.productName ?? 'Unknown',
      'name_it':
          product.productNameInLanguages?[OpenFoodFactsLanguage.ITALIAN] ??
          product.productName ??
          'Unknown',
      'name_en':
          product.productNameInLanguages?[OpenFoodFactsLanguage.ENGLISH] ??
          product.productName ??
          'Unknown',
      'name_fr':
          product.productNameInLanguages?[OpenFoodFactsLanguage.FRENCH] ??
          product.productName ??
          'Unknown',
      'name_es':
          product.productNameInLanguages?[OpenFoodFactsLanguage.SPANISH] ??
          product.productName ??
          'Unknown',
      'brands': product.brands ?? 'Unknown',
      'categories': product.categoriesTags ?? [category],
      'kcal':
          product.nutriments?.getValue(
            Nutrient.energyKCal,
            PerSize.oneHundredGrams,
          ) ??
          0.0,
      'carbs':
          product.nutriments?.getValue(
            Nutrient.carbohydrates,
            PerSize.oneHundredGrams,
          ) ??
          0.0,
      'fat':
          product.nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ??
          0.0,
      'protein':
          product.nutriments?.getValue(
            Nutrient.proteins,
            PerSize.oneHundredGrams,
          ) ??
          0.0,
    };
  }

  Future<void> updateFoodTranslations() async {

    final snapshot = await _firestore.collection('foods').get();
    for (var doc in snapshot.docs) {
      final foodData = doc.data();
      if (foodData['id']?.toString().isNotEmpty == true) {
        final barcode = foodData['id'].toString();
        await _retryUpdateProductTranslations(barcode);
      }
    }
  }

  Future<void> _retryUpdateProductTranslations(
    String barcode, {
    int retryCount = 3,
  }) async {
    int attempts = 0;
    while (attempts < retryCount) {
      try {
        await _updateProductTranslations(barcode);
        return; // Esce se l'aggiornamento ha successo
      } catch (e) {
        attempts++;
        if (attempts < retryCount) {
          final waitTimeMinutes = (5 * attempts).clamp(5, 30);
          final waitTime = Duration(minutes: waitTimeMinutes);
          // retry info (debug removed)
          await Future.delayed(waitTime); // Delay with exponential backoff
        } else {
          // retries exceeded (debug removed)
        }
      }
    }
  }

  Future<void> _updateProductTranslations(String barcode) async {
    final conf = ProductQueryConfiguration(
      barcode,
      fields: [ProductField.NAME_IN_LANGUAGES],
      language: OpenFoodFactsLanguage.ITALIAN, // Specifica la lingua
      version: ProductQueryVersion.v3,
    );

    final productResult = await OpenFoodAPIClient.getProductV3(conf);
    final product = productResult.product;

    // ignore: unrelated_type_equality_checks
    if (productResult.status == 1 && product != null) {
      await _firestore.collection('foods').doc(barcode).update({
        'name': product.productName ?? 'Unknown',
        'name_it':
            product.productNameInLanguages?[OpenFoodFactsLanguage.ITALIAN] ??
            product.productName ??
            'Unknown',
        'name_en':
            product.productNameInLanguages?[OpenFoodFactsLanguage.ENGLISH] ??
            product.productName ??
            'Unknown',
        'name_fr':
            product.productNameInLanguages?[OpenFoodFactsLanguage.FRENCH] ??
            product.productName ??
            'Unknown',
        'name_es':
            product.productNameInLanguages?[OpenFoodFactsLanguage.SPANISH] ??
            product.productName ??
            'Unknown',
      });
    } else {
      // not found or not OK (debug removed)
    }
  }

  void stopImport() {
    _isImporting = false;
  }

  Future<void> normalizeNames() async {
    final snapshot = await _firestore.collection('foods').get();
    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final normalizedData = {
        'name': data['name'].toString().toLowerCase(),
        'name_en': data['name_en']?.toString().toLowerCase(),
        'name_it': data['name_it']?.toString().toLowerCase(),
        'name_fr': data['name_fr']?.toString().toLowerCase(),
        'name_es': data['name_es']?.toString().toLowerCase(),
      };

      batch.update(doc.reference, normalizedData);
    }

    await batch.commit();
  }
}
