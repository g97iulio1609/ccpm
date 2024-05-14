import 'package:alphanessone/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart';
import 'meals_model.dart';
import 'meals_services.dart';
import 'macros_services.dart';

class FoodList extends ConsumerWidget {
  final DateTime selectedDate;

  const FoodList({required this.selectedDate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return StreamBuilder<List<Meal>>(
      stream: mealsService.getUserMealsByDate(userId: userId, date: selectedDate),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final meals = snapshot.data!;
          return ListView(
            children: [
              _buildMealSection(context, ref, 'Breakfast', meals.firstWhere((meal) => meal.mealType == 'Breakfast', orElse: () => Meal.emptyMeal(userId, selectedDate, 'Breakfast'))),
              _buildMealSection(context, ref, 'Lunch', meals.firstWhere((meal) => meal.mealType == 'Lunch', orElse: () => Meal.emptyMeal(userId, selectedDate, 'Lunch'))),
              _buildMealSection(context, ref, 'Dinner', meals.firstWhere((meal) => meal.mealType == 'Dinner', orElse: () => Meal.emptyMeal(userId, selectedDate, 'Dinner'))),
              for (int i = 0; i < _getSnackMeals(meals).length; i++)
                _buildMealSection(context, ref, 'Snack ${i + 1}', _getSnackMeals(meals)[i]),
              _buildAddSnackButton(context, _getSnackMeals(meals).length),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  List<Meal> _getSnackMeals(List<Meal> meals) {
    return meals.where((meal) => meal.mealType.startsWith('Snack')).toList();
  }

  Widget _buildMealSection(BuildContext context, WidgetRef ref, String mealName, Meal meal) {
    final macrosService = ref.watch(macrosServiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.black,
        child: ExpansionTile(
          title: Text(
            mealName,
            style: const TextStyle(color: Colors.white),
          ),
          children: [
            for (String foodId in meal.foodIds)
              FutureBuilder<Food?>(
                future: macrosService.getFoodById(foodId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final food = snapshot.data!;
                    return _buildFoodItem(context, ref, meal, food);
                  } else if (snapshot.hasError) {
                    return ListTile(
                      title: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                    );
                  } else {
                    return const ListTile(
                      title: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ListTile(
              title: const Text('Add Food', style: TextStyle(color: Colors.orange)),
              onTap: () {
                // TODO: Implement Add Food functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, WidgetRef ref, Meal meal, Food food) {
    final mealsService = ref.read(mealsServiceProvider);
    return ListTile(
      leading: const Icon(Icons.fastfood, color: Colors.white),
      title: Text(food.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text('${food.quantity} ${food.quantityUnit}', style: const TextStyle(color: Colors.white)),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.white),
        onPressed: () {
          mealsService.removeFoodFromMeal(mealId: meal.id!, food: food);
        },
      ),
    );
  }

  Widget _buildAddSnackButton(BuildContext context, int currentSnacksCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement Add Snack functionality
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: Text('Add Snack ${currentSnacksCount + 1}'),
      ),
    );
  }
}
