import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models&Services/macros_model.dart' as macros;
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/meals_services.dart';
import 'package:google_fonts/google_fonts.dart';

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
            child: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
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

    return FutureBuilder<Map<String, double>>(
      future: mealsService.getTotalNutrientsForMeal(meal.userId, meal.id!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final totalNutrients = snapshot.data!;
          final subtitle = 'C:${totalNutrients['carbs']}g P:${totalNutrients['proteins']}g F:${totalNutrients['fats']}g, ${totalNutrients['calories']}Kcal';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: ExpansionTile(
                backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                collapsedBackgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
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
                          title: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
                        );
                      } else {
                        return const ListTile(
                          title: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Add Food', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.primary)),
                    onTap: () {
                      context.push(
                        '/food_tracker/food_selector',
                        extra: meal,
                      );
                    },
                  ),
                  ListTile(
                    title: Text('Duplicate Meal', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.primary)),
                    onTap: () async {
                      await _showDuplicateDialog(context, ref, meal, mealsList);
                    },
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: ExpansionTile(
                title: Text(
                  mealName,
                  style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface),
                ),
                children: [
                  ListTile(
                    title: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: ExpansionTile(
                title: Text(
                  mealName,
                  style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface),
                ),
                children: const [
                  ListTile(
                    title: CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildFoodItem(BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    final mealsService = ref.read(mealsServiceProvider);
    return ListTile(
      leading: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onSurface),
      title: Text(food.name, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(
        'C:${food.carbs}g P:${food.protein}g F:${food.fat}g, ${food.kcal}Kcal',
        style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
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
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurface),
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
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text('Add Snack ${currentSnacksCount + 1}'),
      ),
    );
  }

  Future<void> _showDuplicateDialog(BuildContext context, WidgetRef ref, meals.Meal sourceMeal, List<meals.Meal> mealsList) async {
    final mealsService = ref.read(mealsServiceProvider);

    final selectedMeal = await showDialog<meals.Meal>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Destination Meal', style: GoogleFonts.roboto()),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: mealsList.length,
              itemBuilder: (BuildContext context, int index) {
                final meal = mealsList[index];
                return ListTile(
                  title: Text(meal.mealType, style: GoogleFonts.roboto()),
                  onTap: () {
                    Navigator.of(context).pop(meal);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedMeal != null) {
      final overwriteExisting = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Overwrite Existing Foods?', style: GoogleFonts.roboto()),
            content: Text('Do you want to overwrite existing foods in the selected meal or add the new foods to it?', style: GoogleFonts.roboto()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Add to Existing', style: GoogleFonts.roboto()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Overwrite', style: GoogleFonts.roboto()),
              ),
            ],
          );
        },
      );

      if (overwriteExisting != null) {
        await mealsService.duplicateMeal(
          userId: sourceMeal.userId,
          sourceMealId: sourceMeal.id!,
          targetMealId: selectedMeal.id!,
          overwriteExisting: overwriteExisting,
        );
      }
    }
  }
}
