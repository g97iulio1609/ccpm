import 'package:alphanessone/nutrition/models/macros_services.dart';
import 'package:alphanessone/nutrition/models/macros_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FoodAdd extends HookConsumerWidget {
  final String id; // Added the mealId parameter

  const FoodAdd({super.key, required this.id}); // Modified constructor to accept mealId

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    void saveFood() {
      final portion = '${servingSizeValueController.text}${servingSizeUnitController.value}';

      final food = Food(
        id: '', // Pass the mealId
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
