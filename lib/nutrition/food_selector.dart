import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart' as macros;
import 'meals_model.dart' as meals;
import 'meals_services.dart';
import 'macros_services.dart';
import 'autotype.dart';

class FoodSelector extends ConsumerStatefulWidget {
  final meals.Meal meal;

  const FoodSelector({required this.meal, Key? key}) : super(key: key);

  @override
  _FoodSelectorState createState() => _FoodSelectorState();
}

class _FoodSelectorState extends ConsumerState<FoodSelector> {
  final TextEditingController _quantityController = TextEditingController(text: '100');
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _selectedFoodId;
  double _quantity = 100.0;
  String _unit = 'g'; // Default unit

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _selectedFoodId != null ? _saveFood : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AutoTypeField(
              controller: _searchController,
              focusNode: _focusNode,
              onSelected: (macros.Food food) {
                setState(() {
                  _selectedFoodId = food.id;
                });
              },
            ),
            if (_selectedFoodId != null)
              _buildSelectedFoodDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFoodDetails(BuildContext context) {
    final macrosService = ref.watch(macrosServiceProvider);

    return FutureBuilder<macros.Food?>(
      future: macrosService.getFoodById(_selectedFoodId!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final food = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text(
                food.name,
                style: Theme.of(context).textTheme.headline6,
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
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Macro Nutrients:'),
              Text('Protein: ${food.protein}g'),
              Text('Carbohydrates: ${food.carbs}g'),
              Text('Fat: ${food.fat}g'),
              Text('Calories: ${food.kcal}kcal'),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  void _saveFood() async {
    try {
      final mealsService = ref.read(mealsServiceProvider);
      final macrosService = ref.read(macrosServiceProvider);

      if (_selectedFoodId == null) {
        throw Exception("Selected food ID is null");
      }

      final food = await macrosService.getFoodById(_selectedFoodId!);
      if (food == null) {
        throw Exception("Selected food is null");
      }

      final adjustedFood = macros.Food(
        id: food.id,
        name: food.name,
        kcal: food.kcal * _quantity / 100,
        carbs: food.carbs * _quantity / 100,
        fat: food.fat * _quantity / 100,
        protein: food.protein * _quantity / 100,
        quantity: _quantity,
        portion: _unit,
      );

      await mealsService.addFoodToMeal(
        mealId: widget.meal.id!,
        food: adjustedFood,
      );

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving food: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
