import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart' as macros;
import 'meals_model.dart' as meals;
import 'meals_services.dart';
import 'macros_services.dart';
import 'autotype.dart';

class FoodSelector extends ConsumerStatefulWidget {
  final meals.Meal meal;
  final macros.Food? food;

  const FoodSelector({required this.meal, this.food, super.key});

  @override
  _FoodSelectorState createState() => _FoodSelectorState();
}

class _FoodSelectorState extends ConsumerState<FoodSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '100');
  String _selectedFoodId = '';
  double _quantity = 100.0;
  String _unit = 'g'; // Default unit

  @override
  void initState() {
    super.initState();
    if (widget.food != null) {
      _selectedFoodId = widget.food!.id!;
      _quantity = widget.food!.quantity;
      _quantityController.text = widget.food!.quantity.toString();
      _unit = widget.food!.quantityUnit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _selectedFoodId.isNotEmpty ? _saveFood : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.food == null)
              AutoTypeField(
                controller: _searchController,
                focusNode: FocusNode(),
                onSelected: (macros.Food food) {
                  setState(() {
                    _selectedFoodId = food.id!;
                    debugPrint('AutoTypeField: Selected food ID: $_selectedFoodId');
                  });
                },
              ),
            if (_selectedFoodId.isNotEmpty)
              _buildSelectedFoodDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFoodDetails(BuildContext context) {
    final macrosService = ref.watch(macrosServiceProvider);

    return FutureBuilder<macros.Food?>(
      future: macrosService.getFoodById(_selectedFoodId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          final food = snapshot.data!;
          debugPrint('FutureBuilder: Retrieved food: ${food.toJson()}');
          return Column(
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
                          debugPrint('TextField: Quantity changed to: $_quantity');
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
                        debugPrint('DropdownButton: Unit changed to: $_unit');
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Macro Nutrients:'),
              Text('Protein: ${food.protein}g'),
              Text('Carbohydrates: ${food.carbs}g'),
              Text('Fat: ${food.fat}g'),
              Text('Calories: ${food.kcal}kcal'),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const Text('No data');
        }
      },
    );
  }

  Future<void> _saveFood() async {
    try {
      final mealsService = ref.read(mealsServiceProvider);
      final macrosService = ref.read(macrosServiceProvider);

      debugPrint('_saveFood: Selected food ID: $_selectedFoodId');
      final food = await macrosService.getFoodById(_selectedFoodId);
      debugPrint('_saveFood: Retrieved food: ${food?.toJson()}');

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

        debugPrint('_saveFood: Saving adjusted food: ${adjustedFood.toJson()}');

        // Check if meal exists, if not create it
        debugPrint('_saveFood: Checking if meal exists with ID: ${widget.meal.id}');
        var meal = await mealsService.getMealById(widget.meal.id ?? '');
        if (meal == null) {
          debugPrint('_saveFood: Meal not found, creating new meal');
          meal = meals.Meal(
            userId: widget.meal.userId,
            dailyStatsId: widget.meal.dailyStatsId,
            date: widget.meal.date,
            mealType: widget.meal.mealType,
          );
          final newMealId = await mealsService.addMeal(meal, widget.meal.dailyStatsId);
          debugPrint('_saveFood: New meal ID received: $newMealId');
          meal = meal.copyWith(id: newMealId); // Assign the generated ID
          debugPrint('_saveFood: Created new meal with ID: ${meal.id}');
        } else {
          debugPrint('_saveFood: Meal found with ID: ${meal.id}');
        }

        if (widget.food == null) {
          debugPrint('_saveFood: Adding food to meal with ID: ${meal.id}');
          await mealsService.addFoodToMeal(
            mealId: meal.id!,
            food: adjustedFood,
            quantity: _quantity,
          );
          debugPrint('_saveFood: Food added to meal successfully');
        } else {
          debugPrint('_saveFood: Updating food in meal with ID: ${meal.id}');
          await mealsService.updateFoodInMeal(
            myFoodId: widget.food!.id!,
            newQuantity: _quantity,
          );
          debugPrint('_saveFood: Food updated in meal successfully');
        }

        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('_saveFood: Error saving food: $e');
    }
  }
}
