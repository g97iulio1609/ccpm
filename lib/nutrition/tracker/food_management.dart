import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../services/food_services.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
import 'package:alphanessone/UI/components/button.dart';

final foodServiceProvider = Provider<FoodService>((ref) {
  return FoodService(FirebaseFirestore.instance);
});

class FoodManagement extends HookConsumerWidget {
  const FoodManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodService = ref.read(foodServiceProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final glassEnabled = ref.watch(uiGlassEnabledProvider);

    final importPagesController = useTextEditingController(text: '10');
    final importDelayController = useTextEditingController(text: '60');

    final List<String> categories = [
      'pasta',
      'meat',
      'fish',
      'legumes',
      'milk',
      'dairy',
      'spices',
      'beverages',
      'grains',
      'cereals',
      'bread',
      'cereal',
      'biscuits',
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

      await foodService.importFoods(
        pages: pages,
        mainCategories: selectedCategories.value,
        language: mapStringToLanguage(selectedLanguage.value),
        country: mapStringToCountry(selectedCountry.value),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import completed for $pages pages of categories: ${selectedCategories.value}',
          ),
        ),
      );
    }

    void stopImport() {
      foodService.stopImport();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import stopped')));
    }

    void updateTranslations() {
      foodService.updateFoodTranslations();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Translations update started')));
    }

    void normalizeNames() async {
      await foodService.normalizeNames();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Normalization completed')));
    }

    final Widget childContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Import Foods',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<int>(
            future: foodService.getTotalFoodsCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  'Error loading food count',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
                );
              } else {
                return Text('Total foods: ${snapshot.data}', style: theme.textTheme.titleLarge);
              }
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                MultiSelectDialogField(
                  items: categories.map((e) => MultiSelectItem<String>(e, e)).toList(),
                  title: Text(
                    'Categories',
                    style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
                  ),
                  selectedColor: cs.primary,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(color: cs.outline.withAlpha(51), width: 1),
                  ),
                  buttonIcon: Icon(Icons.arrow_drop_down, color: cs.onSurface),
                  buttonText: Text(
                    'Select Categories',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                  onConfirm: (results) {
                    selectedCategories.value = results.cast<String>();
                  },
                  itemsTextStyle: TextStyle(color: cs.onSurface),
                  chipDisplay: MultiSelectChipDisplay(
                    textStyle: TextStyle(color: cs.onPrimary),
                    chipColor: cs.primary,
                    decoration: BoxDecoration(border: Border.all(color: cs.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLanguage.value,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: cs.outline.withAlpha(51)),
                    ),
                  ),
                  dropdownColor: cs.surface,
                  style: TextStyle(color: cs.onSurface),
                  onChanged: (String? newValue) {
                    selectedLanguage.value = newValue!;
                  },
                  items: languages.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCountry.value,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: cs.outline.withAlpha(51)),
                    ),
                  ),
                  dropdownColor: cs.surface,
                  style: TextStyle(color: cs.onSurface),
                  onChanged: (String? newValue) {
                    selectedCountry.value = newValue!;
                  },
                  items: countries.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: importPagesController,
                        decoration: InputDecoration(
                          labelText: 'Number of Pages',
                          labelStyle: TextStyle(color: cs.onSurfaceVariant),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: cs.outline.withAlpha(51)),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: cs.onSurface),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: importDelayController,
                        decoration: InputDecoration(
                          labelText: 'Delay (seconds)',
                          labelStyle: TextStyle(color: cs.onSurfaceVariant),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: cs.outline.withAlpha(51)),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AppButton(
                      label: 'Start Import',
                      onPressed: startImport,
                      variant: AppButtonVariant.primary,
                    ),
                    AppButton(
                      label: 'Stop Import',
                      onPressed: stopImport,
                      variant: AppButtonVariant.filled,
                      glass: false,
                      backgroundColor: cs.error,
                      iconColor: cs.onError,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Update Translations',
                  onPressed: updateTranslations,
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Normalize Names',
                  onPressed: normalizeNames,
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 24),
                StreamBuilder<Map<String, int>>(
                  stream: foodService.importProgressStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text(
                        'No import progress',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      );
                    }
                    final progress = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: progress.entries.map((entry) {
                        return Text(
                          '${entry.key}: ${entry.value} products imported',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: glassEnabled
          ? GlassLite(padding: EdgeInsets.zero, radius: 0, child: childContent)
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.surface, cs.surfaceContainerHighest.withAlpha(128)],
                ),
              ),
              child: childContent,
            ),
    );
  }
}
