import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models&Services/macros_model.dart' as macros;
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/meals_services.dart';

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
              _buildMealSection(context, ref, 'Breakfast', mealsList.firstWhere((meal) => meal.mealType == 'Breakfast', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, selectedDate, 'Breakfast')), mealsList),
              _buildMealSection(context, ref, 'Lunch', mealsList.firstWhere((meal) => meal.mealType == 'Lunch', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, selectedDate, 'Lunch')), mealsList),
              _buildMealSection(context, ref, 'Dinner', mealsList.firstWhere((meal) => meal.mealType == 'Dinner', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, selectedDate, 'Dinner')), mealsList),
              for (int i = 0; i < _getSnackMeals(mealsList).length; i++)
                _buildMealSection(context, ref, 'Snack ${i + 1}', _getSnackMeals(mealsList)[i], mealsList, i),
              _buildAddSnackButton(context, ref, userId, mealsList.isNotEmpty ? mealsList.first.dailyStatsId : '', selectedDate, _getSnackMeals(mealsList).length),
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

  Widget _buildMealSection(BuildContext context, WidgetRef ref, String mealName, meals.Meal meal, List<meals.Meal> mealsList, [int? snackIndex]) {
    final mealsService = ref.watch(mealsServiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.black,
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mealName,
                style: const TextStyle(color: Colors.white),
              ),
              if (snackIndex != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    final snackMeals = _getSnackMeals(mealsList);
                    if (snackMeals.length > 1) {
                      await mealsService.deleteSnack(userId: meal.userId, mealId: meal.id!);
                    }
                  },
                ),
            ],
          ),
          children: [
            FutureBuilder<List<macros.Food>>(
              future: mealsService.getFoodsForMeals(userId: meal.userId, mealId: meal.id!),
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
                context.push(
                  '/food_tracker/food_selector',
                  extra: meal,
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
              context.push(
                Uri(
                  path: '/food_tracker/food_selector',
                  queryParameters: {'myFoodId': food.id},
                ).toString(),
                extra: meal,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              mealsService.removeFoodFromMeal(userId: meal.userId, mealId: meal.id!, myFoodId: food.id!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddSnackButton(BuildContext context, WidgetRef ref, String userId, String dailyStatsId, DateTime date, int currentSnacksCount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          if (dailyStatsId.isNotEmpty) {
            final mealsService = ref.read(mealsServiceProvider);
            await mealsService.createSnack(userId: userId, dailyStatsId: dailyStatsId, date: date);
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0), backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text('Add Snack ${currentSnacksCount + 1}'),
      ),
    );
  }
}
