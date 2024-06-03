import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models&Services/macros_model.dart' as macros;
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/meals_services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'food_selector.dart'; // Import FoodSelector

class FavoriteMealDetail extends ConsumerStatefulWidget {
  final meals.Meal meal;

  const FavoriteMealDetail({required this.meal, super.key});

  @override
  _FavoriteMealDetailState createState() => _FavoriteMealDetailState();
}

class _FavoriteMealDetailState extends ConsumerState<FavoriteMealDetail> {
  final List<String> _selectedFoods = [];
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final mealsService = ref.watch(mealsServiceProvider);

    return Scaffold(

      body: StreamBuilder<List<macros.Food>>(
        stream: mealsService.getFoodsForMealStream(userId: widget.meal.userId, mealId: widget.meal.id!),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final foods = snapshot.data!;
            return ListView.builder(
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return _buildFoodItem(context, ref, food);
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onError)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(
            '/food_tracker/food_selector',
            extra: {
              'meal': widget.meal.toMap(), // Convertiamo l'oggetto Meal in Map<String, dynamic>
              'isFavoriteMeal': true,
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, WidgetRef ref, macros.Food food) {
    final isSelected = _selectedFoods.contains(food.id);

    return GestureDetector(
      onLongPress: () => _onFoodLongPress(food.id!),
      onTap: () => _onFoodTap(context, food.id!),
      child: Container(
        color: isSelected ? Colors.grey.withOpacity(0.3) : Colors.transparent,
        child: Slidable(
          key: Key(food.id!),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  context.push(
                    Uri(
                      path: '/food_tracker/food_selector',
                      queryParameters: {'myFoodId': food.id},
                    ).toString(),
                    extra: {
                      'meal': widget.meal.toMap(), // Convertiamo l'oggetto Meal in Map<String, dynamic>
                      'myFoodId': food.id,
                      'isFavoriteMeal': true,
                    },
                  );
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _removeFood(food.id!),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: ListTile(
            title: Text(food.name, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
            subtitle: Text(
              'C:${food.carbs.toStringAsFixed(2)}g P:${food.protein.toStringAsFixed(2)}g F:${food.fat.toStringAsFixed(2)}g, ${food.kcal.toStringAsFixed(2)}Kcal',
              style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }

  void _onFoodLongPress(String foodId) {
    setState(() {
      _isSelectionMode = true;
      _selectedFoods.add(foodId);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selection mode enabled')));
  }

  void _onFoodTap(BuildContext context, String foodId) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedFoods.contains(foodId)) {
          _selectedFoods.remove(foodId);
        } else {
          _selectedFoods.add(foodId);
        }
      });
    } else {
      context.push(
        Uri(
          path: '/food_tracker/food_selector',
          queryParameters: {'myFoodId': foodId},
        ).toString(),
        extra: {
          'meal': widget.meal.toMap(), // Convertiamo l'oggetto Meal in Map<String, dynamic>
          'myFoodId': foodId,
          'isFavoriteMeal': true,
        },
      );
    }
  }

  void _deleteSelectedFoods() async {
    final mealsService = ref.read(mealsServiceProvider);
    for (final foodId in _selectedFoods) {
      await mealsService.removeFoodFromFavoriteMeal(userId: widget.meal.userId, mealId: widget.meal.id!, myFoodId: foodId);
    }
    setState(() {
      _selectedFoods.clear();
      _isSelectionMode = false;
    });
  }

  void _removeFood(String foodId) async {
    final mealsService = ref.read(mealsServiceProvider);
    await mealsService.removeFoodFromFavoriteMeal(userId: widget.meal.userId, mealId: widget.meal.id!, myFoodId: foodId);
    setState(() {
      _selectedFoods.remove(foodId);
    });
  }
}
