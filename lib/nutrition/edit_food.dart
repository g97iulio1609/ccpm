import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart' as macros;
import 'meals_services.dart';

class EditFoodScreen extends ConsumerStatefulWidget {
  final String mealId;
  final macros.Food food;

  const EditFoodScreen({required this.mealId, required this.food, Key? key}) : super(key: key);

  @override
  _EditFoodScreenState createState() => _EditFoodScreenState();
}

class _EditFoodScreenState extends ConsumerState<EditFoodScreen> {
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.food.quantity.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Food'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFood,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.food.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFood() async {
    final newQuantity = double.tryParse(_quantityController.text) ?? widget.food.quantity;
    final mealsService = ref.read(mealsServiceProvider);

    try {
      await mealsService.updateFoodInMeal(myFoodId: widget.food.id!, newQuantity: newQuantity);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving food: $e');
    }
  }
}
