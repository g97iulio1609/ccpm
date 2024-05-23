import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../models&Services/macros_model.dart';
import '../models&Services/macros_services.dart';
import '../models&Services/food_services.dart';

final foodServiceProvider = Provider<FoodService>((ref) {
  return FoodService(FirebaseFirestore.instance);
});

class FoodManagement extends HookConsumerWidget {
  const FoodManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodService = ref.read(foodServiceProvider);
    final macrosService = ref.read(macrosServiceProvider);

    final descriptionController = useTextEditingController();
    final numberOfServingsController = useState(1);
    final servingSizeValueController = useTextEditingController();
    final servingSizeUnitController = useState('g');
    final cookedController = useState(false);
    final notesController = useTextEditingController();
    final barcodeController = useTextEditingController();
    final caloriesController = useTextEditingController(text: '0');
    final proteinController = useTextEditingController(text: '0');
    final carbohydratesController = useTextEditingController(text: '0');
    final fatController = useTextEditingController(text: '0');
    final importPagesController = useTextEditingController(text: '10');
    final importDelayController = useTextEditingController(text: '60');

    final List<String> categories = [
      'pasta', 'meat', 'fish', 'legumes', 'milk', 'dairy', 'spices', 'beverages',
      'grains', 'cereals', 'bread', 'cereal', 'eggs', 'fresh-fruits', 'fresh-vegetables',
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

    void saveFood() {
      final portion = '${servingSizeValueController.text}${servingSizeUnitController.value}';

      final food = Food(
        name: descriptionController.text,
        carbs: double.tryParse(carbohydratesController.text) ?? 0,
        fat: double.tryParse(fatController.text) ?? 0,
        protein: double.tryParse(proteinController.text) ?? 0,
        kcal: double.tryParse(caloriesController.text) ?? 0,
        quantity: numberOfServingsController.value.toDouble(),
        portion: portion,
      );

      macrosService.addFood(food);
      Navigator.of(context).pop();
    }

    void cancel() {
      Navigator.of(context).pop();
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: cookedController.value,
                    onChanged: (value) => cookedController.value = value,
                    title: const Text('Cooked'),
                    activeColor: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Macronutrients',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildNutrientRow('Protein', proteinController, 'g'),
                  _buildNutrientRow('Carbohydrates', carbohydratesController, 'g'),
                  _buildNutrientRow('Fat', fatController, 'g'),
                  const SizedBox(height: 8),
                  _buildNutrientRow('Calories', caloriesController, 'kcal'),
                  const SizedBox(height: 16),
                  const Text(
                    'Servings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Number of Servings'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (numberOfServingsController.value > 1) {
                            numberOfServingsController.value--;
                          }
                        },
                      ),
                      Text(numberOfServingsController.value.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => numberOfServingsController.value++,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: servingSizeValueController,
                          decoration: const InputDecoration(
                            labelText: 'Serving Size',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: servingSizeUnitController.value,
                        onChanged: (String? newValue) {
                          servingSizeUnitController.value = newValue!;
                        },
                        items: <String>['g', 'ml', 'oz']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Additional',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Import Foods',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  MultiSelectChip(
                    categories,
                    selectedCategories: selectedCategories.value,
                    onSelectionChanged: (selectedList) {
                      selectedCategories.value = selectedList;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedLanguage.value,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCountry.value,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: importPagesController,
                          decoration: const InputDecoration(
                            labelText: 'Number of Pages',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: importDelayController,
                          decoration: const InputDecoration(
                            labelText: 'Delay (seconds)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: startImport,
                    child: const Text('Start Import'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: stopImport,
                    child: const Text('Stop Import'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: updateTranslations,
                    child: const Text('Update Translations'),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<Map<String, int>>(
                    stream: foodService.importProgressStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('No import progress');
                      }
                      final progress = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: progress.entries.map((entry) {
                          return Text('${entry.key}: ${entry.value} products imported');
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: saveFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, TextEditingController controller, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              suffixText: unit,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

class MultiSelectChip extends StatelessWidget {
  final List<String> categories;
  final List<String> selectedCategories;
  final Function(List<String>) onSelectionChanged;

  const MultiSelectChip(this.categories, {super.key, required this.selectedCategories, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: categories.map((category) {
        final isSelected = selectedCategories.contains(category);
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              selectedCategories.add(category);
            } else {
              selectedCategories.remove(category);
            }
            onSelectionChanged(List.from(selectedCategories)); // Create a new list instance
          },
        );
      }).toList(),
    );
  }
}
