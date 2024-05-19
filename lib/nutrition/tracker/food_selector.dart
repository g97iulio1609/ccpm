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
    debugPrint('initState: myFoodId = ${widget.myFoodId}');
    if (widget.myFoodId != null) {
      _selectedFoodId = widget.myFoodId!;
      _foodFuture = _loadFoodData(widget.myFoodId!);
    }
  }

  Future<macros.Food?> _loadFoodData(String foodId) async {
    debugPrint('_loadFoodData: Loading food data for ID = $foodId');
    final mealsService = ref.read(mealsServiceProvider);
    final food = await mealsService.getMyFoodById(foodId);
    if (food != null) {
      debugPrint('_loadFoodData: Food data loaded: ${food.toJson()}');
      setState(() {
        _selectedFoodId = food.id!;
        _loadedFood = food;
        _quantity = food.quantity;
        _unit = food.quantityUnit;
        _quantityController.text = food.quantity.toString();
        _updateMacronutrientValues(food);
      });
      return food;
    } else {
      debugPrint('_loadFoodData: No food data found for ID = $foodId');
      setState(() {
        _selectedFoodId = '';
        _loadedFood = null;
      });
      return null;
    }
  }

  void _updateMacronutrientValues(macros.Food food) {
    debugPrint('_updateMacronutrientValues: Updating macronutrient values for food: ${food.toJson()}');
    setState(() {
      _proteinValue = food.protein * _quantity / 100;
      _carbsValue = food.carbs * _quantity / 100;
      _fatValue = food.fat * _quantity / 100;
      _kcalValue = food.kcal * _quantity / 100;
    });
  }

  Future<void> savefood() async {
    debugPrint('Save button pressed');
    try {
      final mealsService = ref.read(mealsServiceProvider);
      final macrosService = ref.read(macrosServiceProvider);

      debugPrint('savefood: Selected food ID: $_selectedFoodId');
      final food = _loadedFood; // Use the loaded food
      debugPrint('savefood: Loaded food: ${food?.toJson()}');

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

        debugPrint('savefood: Saving adjusted food: ${adjustedFood.toJson()}');

        if (widget.myFoodId == null) {
          // Add new food to meal
          debugPrint('savefood: Adding new food to meal with ID: ${widget.meal.id}');
          await mealsService.addFoodToMeal(
            mealId: widget.meal.id!,
            food: adjustedFood,
            quantity: _quantity,
          );
        } else {
          // Update existing food in myfoods collection
          debugPrint('savefood: Updating existing food in myfoods collection');
          await mealsService.updateMyFood(
            myFoodId: widget.myFoodId!,
            updatedFood: adjustedFood,
          );
        }

        debugPrint('savefood: Food added/updated successfully');

        widget.onSave?.call();
        context.pop(); // Go back to the previous screen
      }
    } catch (e) {
      debugPrint('savefood: Error saving food: $e');
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
                    _updateMacronutrientValues(food);
                    debugPrint('AutoTypeField: Selected food ID: $_selectedFoodId');
                  });
                },
              ),
            if (_selectedFoodId.isNotEmpty)
              Expanded(child: _buildSelectedFoodDetails(context)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: savefood,
              child: const Text('Save and Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFoodDetails(BuildContext context) {
    debugPrint('_buildSelectedFoodDetails: Building details for food ID = $_selectedFoodId');
    final macrosService = ref.watch(macrosServiceProvider);

    return FutureBuilder<macros.Food?>(
      future: _foodFuture ?? macrosService.getFoodById(_selectedFoodId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('FutureBuilder: Waiting for data');
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final food = snapshot.data!;
          debugPrint('FutureBuilder: Retrieved food: ${food.toJson()}');
          _loadedFood = food; // Save the loaded food
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
          debugPrint('FutureBuilder: Error: ${snapshot.error}');
          return Text('Error: ${snapshot.error}');
        } else {
          debugPrint('FutureBuilder: No data');
          return const Text('No data');
        }
      },
    );
  }
}
