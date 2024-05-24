import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../models&Services/food_services.dart';

final foodServiceProvider = Provider<FoodService>((ref) {
  return FoodService(FirebaseFirestore.instance);
});

class FoodManagement extends HookConsumerWidget {
  const FoodManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodService = ref.read(foodServiceProvider);

    final importPagesController = useTextEditingController(text: '10');
    final importDelayController = useTextEditingController(text: '60');

    final List<String> categories = [
      'pasta', 'meat', 'fish', 'legumes', 'milk', 'dairy', 'spices', 'beverages',
      'grains', 'cereals', 'bread', 'cereal', 'biscuits', 'eggs', 'fresh-fruits', 'fresh-vegetables',
      'frozen-fruits', 'frozen-vegetables', 'dried-fruits', 'soft-drinks', 'juices',
      'alcoholic-beverages', 'tea', 'coffee', 'cooking-oils', 'margarine', 'animal-fats',
      'cookies', 'cakes', 'chocolate', 'chips', 'herbs', 'sauces', 'dressings',
      'ready-to-eat-meals', 'canned-foods', 'frozen-meals', 'bakery-products', 'pastries',
      'muffins', 'nuts', 'seeds', 'shellfish', 'salmon', 'tuna', 'honey', 'maple-syrup',
      'sugar', 'baby-formula', 'baby-snacks', 'baby-purees', 'supplements', 'protein-bars', 'health-drinks'
    ];
    final selectedCategories = useState<List<String>>([]);

    final List<String> languages = ['ITALIAN', 'ENGLISH', 'FRENCH', 'SPANISH'];
    final selectedLanguage = useState<String>(languages[0]);

    final List<String> countries = ['Italy', 'USA', 'France', 'Spain'];
    final selectedCountry = useState<String>(countries[0]);

    OpenFoodFactsLanguage mapStringToLanguage(String language) {
      switch (language) {
        case 'ITALIAN':
          return OpenFoodFactsLanguage.ITALIAN;
        case 'ENGLISH':
          return OpenFoodFactsLanguage.ENGLISH;
        case 'FRENCH':
          return OpenFoodFactsLanguage.FRENCH;
        case 'SPANISH':
          return OpenFoodFactsLanguage.SPANISH;
        default:
          return OpenFoodFactsLanguage.UNDEFINED;
      }
    }

    OpenFoodFactsCountry mapStringToCountry(String country) {
      switch (country) {
        case 'Italy':
          return OpenFoodFactsCountry.ITALY;
        case 'USA':
          return OpenFoodFactsCountry.USA;
        case 'France':
          return OpenFoodFactsCountry.FRANCE;
        case 'Spain':
          return OpenFoodFactsCountry.SPAIN;
        default:
          return OpenFoodFactsCountry.USA;
      }
    }

    void startImport() async {
      final pages = int.tryParse(importPagesController.text) ?? 10;
      final delay = int.tryParse(importDelayController.text) ?? 60;

      await foodService.importFoods(
        pages: pages,
        mainCategories: selectedCategories.value,
        language: mapStringToLanguage(selectedLanguage.value),
        country: mapStringToCountry(selectedCountry.value),
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Import completed for $pages pages of categories: ${selectedCategories.value}'),
      ));
    }

    void stopImport() {
      foodService.stopImport();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Import stopped'),
      ));
    }

    void updateTranslations() {
      foodService.updateFoodTranslations();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Translations update started'),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Management Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Import Foods',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  MultiSelectDialogField(
                    items: categories.map((e) => MultiSelectItem<String>(e, e)).toList(),
                    title: const Text("Categories", style: TextStyle(color: Colors.white)),
                    selectedColor: Theme.of(context).primaryColor,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    buttonIcon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    buttonText: const Text(
                      "Select Categories",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onConfirm: (results) {
                      selectedCategories.value = results.cast<String>();
                    },
                    itemsTextStyle: const TextStyle(color: Colors.white), // Added text style
                    chipDisplay: MultiSelectChipDisplay(
                      textStyle: const TextStyle(color: Colors.white),
                      chipColor: Theme.of(context).primaryColor,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLanguage.value,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      selectedLanguage.value = newValue!;
                    },
                    items: languages
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCountry.value,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      selectedCountry.value = newValue!;
                    },
                    items: countries
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: importPagesController,
                          decoration: const InputDecoration(
                            labelText: 'Number of Pages',
                            labelStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: importDelayController,
                          decoration: const InputDecoration(
                            labelText: 'Delay (seconds)',
                            labelStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: startImport,
                        child: const Text('Start Import'),
                      ),
                      ElevatedButton(
                        onPressed: stopImport,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Stop Import'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: updateTranslations,
                    child: const Text('Update Translations'),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<Map<String, int>>(
                    stream: foodService.importProgressStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('No import progress', style: TextStyle(color: Colors.white));
                      }
                      final progress = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: progress.entries.map((entry) {
                          return Text('${entry.key}: ${entry.value} products imported', style: const TextStyle(color: Colors.white));
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
