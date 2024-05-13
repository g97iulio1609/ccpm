import 'package:alphanessone/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart';
import 'macros_services.dart';

class FoodList extends ConsumerWidget {
  final DateTime selectedDate;

  const FoodList({required this.selectedDate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macrosService = ref.watch(macrosServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return StreamBuilder<List<Food>>(
      stream: macrosService.getUserFoodsByDate(userId: userId, date: selectedDate),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final foods = snapshot.data!;
          final meals = _organizeFoodsByMeal(foods);

          return ListView(
            children: [
              _buildMealSection(context, 'Breakfast', meals['Breakfast'] ?? []),
              _buildMealSection(context, 'Lunch', meals['Lunch'] ?? []),
              _buildMealSection(context, 'Dinner', meals['Dinner'] ?? []),
              for (int i = 0; i < meals['Snacks']!.length; i++)
                _buildMealSection(context, 'Snack ${i + 1}', meals['Snacks']![i]),
              _buildAddSnackButton(context, meals['Snacks']!.length),
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

  Map<String, List<Food>> _organizeFoodsByMeal(List<Food> foods) {
    final meals = {'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': <List<Food>>[]};

    for (var food in foods) {
      switch (food.mealType) {
        case 'Breakfast':
          meals['Breakfast']!.add(food);
          break;
        case 'Lunch':
          meals['Lunch']!.add(food);
          break;
        case 'Dinner':
          meals['Dinner']!.add(food);
          break;
        case 'Snack':
          if (meals['Snacks']!.isEmpty) {
            meals['Snacks']!.add([]);
          }
          meals['Snacks']![0].add(food);
          break;
        default:
          if (meals['Snacks']!.isEmpty) {
            meals['Snacks']!.add([]);
          }
          meals['Snacks']![0].add(food);
          break;
      }
    }

    return meals;
  }

  Widget _buildMealSection(BuildContext context, String mealName, List<Food> foods) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.black,
        child: ExpansionTile(
          title: Text(
            mealName,
            style: const TextStyle(color: Colors.white),
          ),
          children: foods.map((food) => _buildFoodItem(context, food)).toList(),
        ),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, Food food) {
    return ListTile(
      leading: const Icon(Icons.fastfood, color: Colors.white),
      title: Text(food.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text('${food.quantity} ${food.quantityUnit}', style: const TextStyle(color: Colors.white)),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.white),
        onPressed: () {
          // TODO: Delete the food entry
        },
      ),
    );
  }

  Widget _buildAddSnackButton(BuildContext context, int currentSnacksCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () {
          // TODO: Add new snack entry logic
        },
        style: ElevatedButton.styleFrom(primary: Colors.orange),
        child: Text('Add Snack ${currentSnacksCount + 1}'),
      ),
    );
  }
}
