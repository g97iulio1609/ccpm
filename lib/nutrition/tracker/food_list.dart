import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models&Services/macros_model.dart' as macros;
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/meals_services.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodList extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const FoodList({required this.selectedDate, super.key});

  @override
  _FoodListState createState() => _FoodListState();
}

class _FoodListState extends ConsumerState<FoodList> {
  final List<String> _selectedFoods = [];
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return StreamBuilder<List<meals.Meal>>(
      stream: mealsService.getUserMealsByDate(userId: userId, date: widget.selectedDate),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final mealsList = snapshot.data!;
          return ListView(
            children: _buildMealSections(context, ref, mealsList, userId),
          );
        } else if (snapshot.hasError) {
          return _buildError(context, snapshot.error.toString());
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  List<Widget> _buildMealSections(BuildContext context, WidgetRef ref, List<meals.Meal> mealsList, String userId) {
    return [
      _buildMealSection(context, ref, 'Breakfast', mealsList.firstWhere((meal) => meal.mealType == 'Breakfast', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, widget.selectedDate, 'Breakfast')), mealsList),
      _buildMealSection(context, ref, 'Lunch', mealsList.firstWhere((meal) => meal.mealType == 'Lunch', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, widget.selectedDate, 'Lunch')), mealsList),
      _buildMealSection(context, ref, 'Dinner', mealsList.firstWhere((meal) => meal.mealType == 'Dinner', orElse: () => meals.Meal.emptyMeal(userId, mealsList.first.dailyStatsId, widget.selectedDate, 'Dinner')), mealsList),
      for (int i = 0; i < _getSnackMeals(mealsList).length; i++)
        _buildMealSection(context, ref, 'Snack ${i + 1}', _getSnackMeals(mealsList)[i], mealsList, i),
      _buildAddSnackButton(context, ref, userId, mealsList.isNotEmpty ? mealsList.first.dailyStatsId : '', widget.selectedDate, _getSnackMeals(mealsList).length),
    ];
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
          return _buildMealCard(context, ref, mealName, meal, mealsList, snapshot.data!);
        } else if (snapshot.hasError) {
          return _buildErrorCard(context, mealName, snapshot.error.toString());
        } else {
          return _buildLoadingCard(context, mealName);
        }
      },
    );
  }

  Widget _buildMealCard(BuildContext context, WidgetRef ref, String mealName, meals.Meal meal, List<meals.Meal> mealsList, Map<String, double> totalNutrients) {
    final subtitle = 'C:${totalNutrients['carbs']?.toStringAsFixed(2)}g P:${totalNutrients['proteins']?.toStringAsFixed(2)}g F:${totalNutrients['fats']?.toStringAsFixed(2)}g, ${totalNutrients['calories']?.toStringAsFixed(2)}Kcal';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: ExpansionTile(
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          collapsedBackgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          title: _buildMealTitle(context, mealName, subtitle, meal, mealsList),
          children: [
            _buildFoodList(context, ref, meal),
            ListTile(
              title: Text('Add Food', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.primary)),
              onTap: () => context.push('/food_tracker/food_selector', extra: meal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTitle(BuildContext context, String mealName, String subtitle, meals.Meal meal, List<meals.Meal> mealsList) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mealName, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
            Text(subtitle, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _onMealMenuSelected(context, ref, value, meal, mealsList),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Meal')),
            const PopupMenuItem(value: 'delete_all', child: Text('Delete All Foods')),
            const PopupMenuItem(value: 'save_as_favorite', child: Text('Save as Favorite')),
            const PopupMenuItem(value: 'apply_favorite', child: Text('Apply Favorite')),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodList(BuildContext context, WidgetRef ref, meals.Meal meal) {
    final mealsService = ref.watch(mealsServiceProvider);

    return FutureBuilder<List<macros.Food>>(
      future: mealsService.getFoodsForMeals(userId: meal.userId, mealId: meal.id!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: snapshot.data!.map((food) => _buildFoodItem(context, ref, meal, food)).toList(),
          );
        } else if (snapshot.hasError) {
          return ListTile(
            title: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          );
        } else {
          return const ListTile(title: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildFoodItem(BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    final isSelected = _selectedFoods.contains(food.id);

    return GestureDetector(
      onLongPress: () => _onFoodLongPress(food.id!),
      onTap: () => _onFoodTap(context, meal, food.id!),
      child: Container(
        color: isSelected ? Colors.grey.withOpacity(0.3) : Colors.transparent,
        child: Slidable(
          key: Key(food.id!),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: _buildSlidableStartActions(context, meal, food),
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: _buildSlidableEndActions(context, ref, meal, food),
          ),
          child: _buildFoodListTile(context, ref, meal, food),
        ),
      ),
    );
  }

  List<SlidableAction> _buildSlidableStartActions(BuildContext context, meals.Meal meal, macros.Food food) {
    return [
      SlidableAction(
        onPressed: (_) => context.push(Uri(path: '/food_tracker/food_selector', queryParameters: {'myFoodId': food.id}).toString(), extra: meal),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: Icons.edit,
        label: 'Edit',
      ),
      SlidableAction(
        onPressed: (_) => context.push('/food_tracker/food_selector', extra: meal),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: Icons.add,
        label: 'Add',
      ),
    ];
  }

  List<SlidableAction> _buildSlidableEndActions(BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    final mealsService = ref.read(mealsServiceProvider);

    return [
      SlidableAction(
        onPressed: (_) async => await mealsService.removeFoodFromMeal(userId: meal.userId, mealId: meal.id!, myFoodId: food.id!),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: Icons.delete,
        label: 'Delete',
      ),
      SlidableAction(
        onPressed: (_) async {
          if (_selectedFoods.isNotEmpty) {
            final mealsList = await _getAllMeals(meal.userId);
            await _showMoveDialog(context, ref, mealsList);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No foods selected')));
          }
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: Icons.move_to_inbox,
        label: 'Move',
      ),
    ];
  }

  ListTile _buildFoodListTile(BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    return ListTile(
      leading: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onSurface),
      title: Text(food.name, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(
        'C:${food.carbs.toStringAsFixed(2)}g P:${food.protein.toStringAsFixed(2)}g F:${food.fat.toStringAsFixed(2)}g, ${food.kcal.toStringAsFixed(2)}Kcal',
        style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _onFoodMenuSelected(context, ref, value, meal, food.id!),
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
          if (_isSelectionMode) const PopupMenuItem(value: 'move', child: Text('Move Selected Foods')),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          textStyle: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
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
                  onTap: () => Navigator.of(context).pop(meal),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedMeal != null) {
      final overwriteExisting = await _showOverwriteDialog(context);
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

  Future<bool?> _showOverwriteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Overwrite Existing Foods?', style: GoogleFonts.roboto()),
          content: Text('Do you want to overwrite existing foods in the selected meal or add the new foods to it?', style: GoogleFonts.roboto()),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Add to Existing', style: GoogleFonts.roboto())),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Overwrite', style: GoogleFonts.roboto())),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAllFoods(BuildContext context, WidgetRef ref, meals.Meal meal) async {
    final confirm = await _showConfirmationDialog(context, 'Delete All Foods', 'Are you sure you want to delete all foods in this meal?');
    if (confirm == true) {
      final mealsService = ref.read(mealsServiceProvider);
      final foods = await mealsService.getFoodsForMeals(userId: meal.userId, mealId: meal.id!);
      for (final food in foods) {
        await mealsService.removeFoodFromMeal(userId: meal.userId, mealId: meal.id!, myFoodId: food.id!);
      }
    }
  }

  Future<void> _showMoveDialog(BuildContext context, WidgetRef ref, List<meals.Meal> mealsList) async {
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
                  onTap: () => Navigator.of(context).pop(meal),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedMeal != null) {
      await mealsService.moveFoods(
        userId: selectedMeal.userId,
        foodIds: _selectedFoods,
        targetMealId: selectedMeal.id!,
      );
      setState(() {
        _selectedFoods.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<List<meals.Meal>> _getAllMeals(String userId) async {
    final mealsService = ref.read(mealsServiceProvider);
    final snapshot = await mealsService.getUserMealsByDate(userId: userId, date: widget.selectedDate).first;
    return snapshot;
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.roboto()),
          content: Text(content, style: GoogleFonts.roboto()),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.roboto())),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: GoogleFonts.roboto())),
          ],
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(child: Text('Error: $error', style: TextStyle(color: Theme.of(context).colorScheme.onError)));
  }

  Widget _buildErrorCard(BuildContext context, String mealName, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: ExpansionTile(
          title: Text(mealName, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
          children: [ListTile(title: Text('Error: $error', style: TextStyle(color: Theme.of(context).colorScheme.onError)))],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, String mealName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: ExpansionTile(
          title: Text(mealName, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
          children: const [ListTile(title: CircularProgressIndicator())],
        ),
      ),
    );
  }

  void _onMealMenuSelected(BuildContext context, WidgetRef ref, String value, meals.Meal meal, List<meals.Meal> mealsList) async {
    final mealsService = ref.read(mealsServiceProvider);
    if (value == 'duplicate') {
      await _showDuplicateDialog(context, ref, meal, mealsList);
    } else if (value == 'delete_all') {
      await _confirmDeleteAllFoods(context, ref, meal);
    } else if (value == 'save_as_favorite') {
      await mealsService.saveMealAsFavorite(meal.userId, meal.id!);
    } else if (value == 'apply_favorite') {
      final favoriteMeals = await mealsService.getFavoriteMeals(meal.userId);
      if (favoriteMeals.isNotEmpty) {
        final selectedFavorite = await showDialog<meals.Meal>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Favorite Meal', style: GoogleFonts.roboto()),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: favoriteMeals.length,
                  itemBuilder: (BuildContext context, int index) {
                    final favMeal = favoriteMeals[index];
                    return ListTile(
                      title: Text(favMeal.mealType, style: GoogleFonts.roboto()),
                      onTap: () => Navigator.of(context).pop(favMeal),
                    );
                  },
                ),
              ),
            );
          },
        );

        if (selectedFavorite != null) {
          await mealsService.applyFavoriteMealToCurrent(meal.userId, selectedFavorite.id!, meal.id!);
        }
      }
    }
  }

  void _onFoodMenuSelected(BuildContext context, WidgetRef ref, String value, meals.Meal meal, String foodId) async {
    if (value == 'edit') {
      context.push(Uri(path: '/food_tracker/food_selector', queryParameters: {'myFoodId': foodId}).toString(), extra: meal);
    } else if (value == 'delete') {
      final mealsService = ref.read(mealsServiceProvider);
      await mealsService.removeFoodFromMeal(userId: meal.userId, mealId: meal.id!, myFoodId: foodId);
    } else if (value == 'move') {
      if (_selectedFoods.isNotEmpty) {
        final mealsList = await _getAllMeals(meal.userId);
        await _showMoveDialog(context, ref, mealsList);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No foods selected')));
      }
    }
  }

  void _onFoodLongPress(String foodId) {
    setState(() {
      _isSelectionMode = true;
      _selectedFoods.add(foodId);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selection mode enabled')));
  }

  void _onFoodTap(BuildContext context, meals.Meal meal, String foodId) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedFoods.contains(foodId)) {
          _selectedFoods.remove(foodId);
        } else {
          _selectedFoods.add(foodId);
        }
      });
    } else {
      context.push(Uri(path: '/food_tracker/food_selector', queryParameters: {'myFoodId': foodId}).toString(), extra: meal);
    }
  }
}
