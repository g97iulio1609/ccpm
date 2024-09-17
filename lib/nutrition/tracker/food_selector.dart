import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/macros_model.dart' as macros;
import '../models/meals_model.dart' as meals;
import '../services/meals_services.dart';
import 'food_autocomplete.dart';
import 'package:go_router/go_router.dart';

class FoodSelector extends ConsumerStatefulWidget {
  final meals.Meal meal;
  final String? myFoodId;
  final VoidCallback? onSave;
  final bool isFavoriteMeal;
  final ScrollController? scrollController; // Aggiunto il parametro

  const FoodSelector({
    required this.meal,
    this.myFoodId,
    this.onSave,
    this.isFavoriteMeal = false,
    this.scrollController, // Aggiunto il parametro
    super.key,
  });

  @override
  FoodSelectorState createState() => FoodSelectorState();
}

class FoodSelectorState extends ConsumerState<FoodSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '100');
  String _selectedFoodId = '';
  double _quantity = 100.0;
  String _unit = 'g';

  double _proteinValue = 0.0;
  double _carbsValue = 0.0;
  double _fatValue = 0.0;
  double _kcalValue = 0.0;

  Future<macros.Food?>? _foodFuture;
  macros.Food? _loadedFood;
  macros.Food? _originalFood;

  @override
  void initState() {
    super.initState();
    if (widget.myFoodId != null) {
      _selectedFoodId = widget.myFoodId!;
      _foodFuture = _loadFoodData(widget.myFoodId!);
    }
  }

  Future<macros.Food?> _loadFoodData(String foodId) async {
    final mealsService = ref.read(mealsServiceProvider);
    final food =
        await mealsService.getMyFoodById(widget.meal.userId, foodId);
    if (food != null) {
      if (mounted) {
        setState(() {
          _updateLoadedFood(food);
          _updateMacronutrientValues(food);
        });
      }
      return food;
    } else {
      if (mounted) {
        setState(() {
          _resetLoadedFood();
        });
      }
      return null;
    }
  }

  void _updateLoadedFood(macros.Food food) {
    setState(() {
      _selectedFoodId = food.id!;
      _loadedFood = food;
      _originalFood = food;
      _quantity = food.quantity ?? 100.0;
      _unit = food.quantityUnit;
      _quantityController.text = _quantity.toString();
    });
  }

  void _resetLoadedFood() {
    setState(() {
      _selectedFoodId = '';
      _loadedFood = null;
    });
  }

  void _updateMacronutrientValues(macros.Food food) {
    setState(() {
      _proteinValue = food.protein * _quantity / 100;
      _carbsValue = food.carbs * _quantity / 100;
      _fatValue = food.fat * _quantity / 100;
      _kcalValue = food.kcal * _quantity / 100;
    });
  }

  Future<void> _saveFood() async {
    try {
      final mealsService = ref.read(mealsServiceProvider);
      final food = _loadedFood;
      if (food != null) {
        final adjustedFood = _createAdjustedFood(food);

        if (widget.myFoodId == null) {
          await _addFood(mealsService, adjustedFood);
        } else {
          await _updateFood(mealsService, adjustedFood);
        }

        widget.onSave?.call();
      }
    } catch (e) {
      debugPrint('saveFood: Error saving food: $e');
    } finally {
      if (mounted) {
        context.pop();
      }
    }
  }

  macros.Food _createAdjustedFood(macros.Food food) {
    return macros.Food(
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
      mealId: widget.meal.id!,
    );
  }

  Future<void> _addFood(
      MealsService mealsService, macros.Food adjustedFood) async {
    if (widget.isFavoriteMeal) {
      await mealsService.addFoodToFavoriteMeal(
        userId: widget.meal.userId,
        mealId: widget.meal.id!,
        food: adjustedFood,
        quantity: _quantity,
      );
    } else {
      await mealsService.addFoodToMeal(
        userId: widget.meal.userId,
        mealId: widget.meal.id!,
        food: adjustedFood,
        quantity: _quantity,
      );
    }
  }

  Future<void> _updateFood(
      MealsService mealsService, macros.Food adjustedFood) async {
    await mealsService.updateMyFood(
      userId: widget.meal.userId,
      myFoodId: widget.myFoodId!,
      updatedFood: adjustedFood,
    );

    if (_originalFood != null) {
      await mealsService.updateMealAndDailyStats(
        widget.meal.userId,
        widget.meal.id!,
        _originalFood!,
        isAdding: false,
      );
      await mealsService.updateMealAndDailyStats(
        widget.meal.userId,
        widget.meal.id!,
        adjustedFood,
        isAdding: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController, // Utilizza lo scrollController passato
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoTypeField(
            controller: _searchController,
            focusNode: FocusNode(),
            onSelected: (macros.Food food) {
              setState(() {
                _updateLoadedFood(food);
                _quantity = 100.0;
                _unit = 'g';
                _quantityController.text = '100';
                _foodFuture = Future.value(food);
                _updateMacronutrientValues(food);
              });
            },
            onChanged: (String pattern) {
              // Gestione dei cambiamenti nel campo di ricerca se necessario
            },
          ),
          if (_selectedFoodId.isNotEmpty || widget.myFoodId != null)
            _buildSelectedFoodDetails(context),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveFood,
            child: const Text('Salva e torna indietro'),
          ),
        ],
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text(
                food.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildQuantityInput(food),
              const SizedBox(height: 16),
              const Text('Macronutrienti:'),
              Text('Proteine: ${_proteinValue.toStringAsFixed(2)}g'),
              Text('Carboidrati: ${_carbsValue.toStringAsFixed(2)}g'),
              Text('Grassi: ${_fatValue.toStringAsFixed(2)}g'),
              Text('Calorie: ${_kcalValue.toStringAsFixed(2)}kcal'),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Errore: ${snapshot.error}');
        } else {
          return const Text('Nessun dato disponibile');
        }
      },
    );
  }

  Widget _buildQuantityInput(macros.Food food) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantità',
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
    );
  }
}
