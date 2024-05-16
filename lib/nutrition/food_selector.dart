import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart' as macros;
import 'meals_model.dart' as meals;
import 'meals_services.dart';
import 'macros_services.dart';
import 'autotype.dart';

class FoodSelector extends ConsumerStatefulWidget {
  final meals.Meal meal;
  final String? myFoodId;

  const FoodSelector({required this.meal, this.myFoodId, super.key});

  @override
  _FoodSelectorState createState() => _FoodSelectorState();
}

class _FoodSelectorState extends ConsumerState<FoodSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '100');
  String _selectedFoodId = '';
  double _quantity = 100.0;
  String _unit = 'g'; // Default unit

  double _proteinValue = 0.0;
  double _carbsValue = 0.0;
  double _fatValue = 0.0;
  double _kcalValue = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.myFoodId != null) {
      _loadFoodData(widget.myFoodId!);
    }
  }

  Future<void> _loadFoodData(String foodId) async {
    final mealsService = ref.read(mealsServiceProvider);
    final food = await mealsService.getMyFoodById(foodId);
    if (food != null) {
      setState(() {
        _selectedFoodId = food.id!;
        _quantity = food.quantity;
        _unit = food.quantityUnit;
        _quantityController.text = food.quantity.toString();
        _updateMacronutrientValues(food);
      });
    }
  }

  void _updateMacronutrientValues(macros.Food food) {
    _proteinValue = food.protein * _quantity / 100;
    _carbsValue = food.carbs * _quantity / 100;
    _fatValue = food.fat * _quantity / 100;
    _kcalValue = food.kcal * _quantity / 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.myFoodId == null ? 'Add Entry' : 'Edit Entry'),
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
            if (widget.myFoodId == null)
              AutoTypeField(
                controller: _searchController,
                focusNode: FocusNode(),
                onSelected: (macros.Food food) {
                  setState(() {
                    _selectedFoodId = food.id!;
                    _updateMacronutrientValues(food);
                    debugPrint('AutoTypeField: Selected food ID: $_selectedFoodId');
                  });
                },
              ),
            if (_selectedFoodId.isNotEmpty || widget.myFoodId != null)
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
                          _updateMacronutrientValues(food);
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
                        _updateMacronutrientValues(food);
                        debugPrint('DropdownButton: Unit changed to: $_unit');
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
          kcal: _kcalValue,
          carbs: _carbsValue,
          fat: _fatValue,
          protein: _proteinValue,
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

        if (widget.myFoodId == null) {
          debugPrint('_saveFood: Adding new food to meal with ID: ${meal.id}');
          await mealsService.addFoodToMeal(
            mealId: meal.id!,
            food: adjustedFood,
            quantity: _quantity,
          );
        } else {
          debugPrint('_saveFood: Updating food in meal with ID: ${meal.id}');
          await mealsService.updateFoodInMeal(
            myFoodId: widget.myFoodId!,
            newQuantity: _quantity,
          );
        }

        debugPrint('_saveFood: Food added/updated in meal successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('_saveFood: Error saving food: $e');
    }
  }
}