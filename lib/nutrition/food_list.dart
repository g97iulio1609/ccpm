import 'package:alphanessone/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart' as macros;
import 'meals_model.dart' as meals;
import 'meals_services.dart';
import 'macros_services.dart';
import 'food_selector.dart';

class FoodList extends ConsumerWidget {
  final DateTime selectedDate;

  const FoodList({required this.selectedDate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return StreamBuilder<List<meals.Meal>>(
      stream: mealsService.getUserMealsByDate(userId: userId, date: selectedDate),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final mealsList = snapshot.data!;
          return ListView(
            children: [
              _buildMealSection(context, ref, 'Breakfast', mealsList.firstWhere((meal) => meal.mealType == 'Breakfast', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, selectedDate, 'Breakfast'))),
              _buildMealSection(context, ref, 'Lunch', mealsList.firstWhere((meal) => meal.mealType == 'Lunch', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, selectedDate, 'Lunch'))),
              _buildMealSection(context, ref, 'Dinner', mealsList.firstWhere((meal) => meal.mealType == 'Dinner', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, selectedDate, 'Dinner'))),
              for (int i = 0; i < _getSnackMeals(mealsList).length; i++)
                _buildMealSection(context, ref, 'Snack ${i + 1}', _getSnackMeals(mealsList)[i]),
              _buildAddSnackButton(context, _getSnackMeals(mealsList).length),
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

  List<meals.Meal> _getSnackMeals(List<meals.Meal> mealsList) {
    return mealsList.where((meal) => meal.mealType.startsWith('Snack')).toList();
  }

  Widget _buildMealSection(BuildContext context, WidgetRef ref, String mealName, meals.Meal meal) {
    final mealsService = ref.watch(mealsServiceProvider);

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
            FutureBuilder<List<macros.Food>>(
              future: mealsService.getFoodsForMeal(meal.id!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final foods = snapshot.data!;
                  return Column(
                    children: foods.map((food) => _buildFoodItem(context, ref, meal, food)).toList(),
                  );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodSelector(meal: meal),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    final mealsService = ref.read(mealsServiceProvider);
    return ListTile(
      leading: const Icon(Icons.fastfood, color: Colors.white),
      title: Text(food.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text('${food.quantity} ${food.portion}', style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodSelector(meal: meal, myFoodId: food.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              mealsService.removeFoodFromMeal(mealId: meal.id!, myFoodId: food.id!);
            },
          ),
        ],
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
