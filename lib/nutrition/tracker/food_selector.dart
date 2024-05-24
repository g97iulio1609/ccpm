import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models&Services/macros_model.dart' as macros;
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/meals_services.dart';
import '../models&Services/macros_services.dart';
import 'autotype.dart';
import 'package:go_router/go_router.dart';

class FoodSelector extends ConsumerStatefulWidget {
  final meals.Meal meal;
  final String? myFoodId;
  final VoidCallback? onSave;

  const FoodSelector({
    required this.meal,
    this.myFoodId,
    this.onSave,
    super.key,
  });

  @override
  FoodSelectorState createState() => FoodSelectorState();
}

class FoodSelectorState extends ConsumerState<FoodSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '100');
  String _selectedFoodId = '';
  double _quantity = 100.0;
  String _unit = 'g'; // Default unit

  double _proteinValue = 0.0;
  double _carbsValue = 0.0;
  double _fatValue = 0.0;
  double _kcalValue = 0.0;

  Future<macros.Food?>? _foodFuture;
  macros.Food? _loadedFood;

  @override
  void initState() {
    super.initState();
    if (widget.myFoodId != null) {
      _selectedFoodId = widget.myFoodId!;
      _foodFuture = _loadFoodData(widget.myFoodId!);
    }
  }

  Future<macros.Food?> _loadFoodData(String foodId) async {
    final macrosService = ref.read(macrosServiceProvider);
    final food = await macrosService.getFoodById(foodId);
    if (food != null) {
      setState(() {
        _selectedFoodId = food.id!;
        _loadedFood = food;
        _quantity = food.quantity ?? 100.0;
        _unit = food.quantityUnit;
        _quantityController.text = _quantity.toString();
        _updateMacronutrientValues(food);
      });
      return food;
    } else {
      setState(() {
        _selectedFoodId = '';
        _loadedFood = null;
      });
      return null;
    }
  }

  void _updateMacronutrientValues(macros.Food food) {
    setState(() {
      _proteinValue = food.protein * _quantity / 100;
      _carbsValue = food.carbs * _quantity / 100;
      _fatValue = food.fat * _quantity / 100;
      _kcalValue = food.kcal * _quantity / 100;
    });
  }

  Future<void> saveFood() async {
    try {
      final mealsService = ref.read(mealsServiceProvider);
      final food = _loadedFood;
      if (food != null) {
        final adjustedFood = macros.Food(
          id: food.id,
          name: food.name,
          kcal: food.kcal * _quantity / 100,
          carbs: food.carbs * _quantity / 100,
          fat: food.fat * _quantity / 100,
          protein: food.protein * _quantity / 100,
          quantity: _quantity,
          quantityUnit: _unit,
          portion: _unit,
          sugar: food.sugar,
          fiber: food.fiber,
          saturatedFat: food.saturatedFat,
          polyunsaturatedFat: food.polyunsaturatedFat,
          monounsaturatedFat: food.monounsaturatedFat,
          transFat: food.transFat,
          cholesterol: food.cholesterol,
          sodium: food.sodium,
          potassium: food.potassium,
          vitaminA: food.vitaminA,
          vitaminC: food.vitaminC,
          calcium: food.calcium,
          iron: food.iron,
        );

        if (widget.myFoodId == null) {
          await mealsService.addFoodToMeal(
            userId: widget.meal.userId!,
            mealId: widget.meal.id!,
            food: adjustedFood,
            quantity: _quantity,
          );
        } else {
          await mealsService.updateMyFood(
            userId: widget.meal.userId!,
            myFoodId: widget.myFoodId!,
            updatedFood: adjustedFood,
          );
        }

        widget.onSave?.call();
        context.pop();
      }
    } catch (e) {
      debugPrint('saveFood: Error saving food: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.myFoodId == null)
              AutoTypeField(
                controller: _searchController,
                focusNode: FocusNode(),
                onSelected: (macros.Food food) {
                  setState(() {
                    _selectedFoodId = food.id!;
                    _loadedFood = food;
                    _quantity = 100.0;
                    _unit = 'g';
                    _quantityController.text = '100';
                    _foodFuture = Future.value(food);
                    _updateMacronutrientValues(food);
                  });
                },
              ),
            if (_selectedFoodId.isNotEmpty)
              Expanded(child: _buildSelectedFoodDetails(context)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveFood,
              child: const Text('Save and Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFoodDetails(BuildContext context) {
    return FutureBuilder<macros.Food?>(
      future: _foodFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final food = snapshot.data!;
          _loadedFood = food;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text(
                  food.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _quantity = double.tryParse(value) ?? 100.0;
                            _updateMacronutrientValues(food);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _unit,
                      items: <String>['g', 'ml', 'oz'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _unit = newValue!;
                          _updateMacronutrientValues(food);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Macro Nutrients:'),
                Text('Protein: ${_proteinValue.toStringAsFixed(2)}g'),
                Text('Carbohydrates: ${_carbsValue.toStringAsFixed(2)}g'),
                Text('Fat: ${_fatValue.toStringAsFixed(2)}g'),
                Text('Calories: ${_kcalValue.toStringAsFixed(2)}kcal'),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const Text('No data');
        }
      },
    );
  }
}
