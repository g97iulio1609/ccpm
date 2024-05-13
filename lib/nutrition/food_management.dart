import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'macros_model.dart';
import 'macros_services.dart';

class FoodManagement extends HookConsumerWidget {
  const FoodManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptionController = useTextEditingController();
    final numberOfServingsController = useState(1);
    final servingSizeController = useTextEditingController();
    final cookedController = useState(false);
    final notesController = useTextEditingController();
    final caloriesController = useTextEditingController(text: '0');
    final proteinController = useTextEditingController(text: '0');
    final carbohydratesController = useTextEditingController(text: '0');
    final fatController = useTextEditingController(text: '0');

    void _saveFood() {
      final food = Food(
        name: descriptionController.text,
        carbs: double.tryParse(carbohydratesController.text) ?? 0,
        fat: double.tryParse(fatController.text) ?? 0,
        protein: double.tryParse(proteinController.text) ?? 0,
        kcal: double.tryParse(caloriesController.text) ?? 0,
        quantity: numberOfServingsController.value.toDouble(),
        portion: double.tryParse(servingSizeController.text) ?? 0,
      );

      final macrosService = ref.read(macrosServiceProvider);
      macrosService.addFood(food);
      Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.orange),
          ),
        ),
        title: const Text('Add Food'),
        actions: [
          TextButton(
            onPressed: _saveFood,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Bananas',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: cookedController.value,
              onChanged: (value) => cookedController.value = value,
              title: const Text('Cooked'),
            ),
            const SizedBox(height: 16),
            const Text('Macronutrients', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            _buildNutrientRow('Protein', proteinController, 'g'),
            _buildNutrientRow('Carbohydrates', carbohydratesController, 'g'),
            _buildNutrientRow('Fat', fatController, 'g'),
            const SizedBox(height: 8),
            _buildNutrientRow('Calories', caloriesController, 'kcal'),
            const SizedBox(height: 16),
            const Text('Servings', style: TextStyle(fontSize: 16)),
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
            TextField(
              controller: servingSizeController,
              decoration: const InputDecoration(
                labelText: 'Serving Size',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Additional', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Barcode: 001234567899'),
            const SizedBox(height: 8),
            const Text('Timestamp: 7:06 PM'),
            const SizedBox(height: 8),
            const Text('Report an Issue', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, TextEditingController controller, String unit) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              suffixText: unit,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}
