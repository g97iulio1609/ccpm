import 'package:alphanessone/nutrition/tracker/food_selector.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models&Services/macros_model.dart' as macros;
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/meals_services.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodList extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const FoodList({required this.selectedDate, super.key});

  @override
  FoodListState createState() => FoodListState();
}

class FoodListState extends ConsumerState<FoodList> {
  final List<String> selectedFoods = [];
  bool isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return Scaffold(
      body: StreamBuilder<List<meals.Meal>>(
        stream: mealsService.getUserMealsByDate(userId: userId, date: widget.selectedDate),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final mealsList = snapshot.data!;
            return ListView(
              children: buildMealSections(context, ref, mealsList, userId),
            );
          } else if (snapshot.hasError) {
            return buildError(context, snapshot.error.toString());
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  List<Widget> buildMealSections(BuildContext context, WidgetRef ref, List<meals.Meal> mealsList, String userId) {
    final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
    List<Widget> mealSections = mealTypes
        .map((mealType) => buildMealSection(context, ref, mealType, getMealByType(mealsList, mealType, userId), mealsList))
        .toList();

    final snackMeals = getSnackMeals(mealsList);
    for (int i = 0; i < snackMeals.length; i++) {
      mealSections.add(buildMealSection(context, ref, 'Snack ${i + 1}', snackMeals[i], mealsList));
    }

    mealSections.add(buildAddSnackButton(context, ref, userId, mealsList.isNotEmpty ? mealsList.first.dailyStatsId : '', widget.selectedDate, snackMeals.length));

    return mealSections;
  }

  meals.Meal getMealByType(List<meals.Meal> mealsList, String mealType, String userId) {
    return mealsList.firstWhere((meal) => meal.mealType == mealType, orElse: () => meals.Meal.emptyMeal(userId, mealsList.isNotEmpty ? mealsList.first.dailyStatsId : '', widget.selectedDate, mealType));
  }

  List<meals.Meal> getSnackMeals(List<meals.Meal> mealsList) {
    return mealsList.where((meal) => meal.mealType.startsWith('Snack')).toList();
  }

  Widget buildMealSection(BuildContext context, WidgetRef ref, String mealName, meals.Meal meal, List<meals.Meal> mealsList) {
    return FutureBuilder<Map<String, double>>(
      future: ref.watch(mealsServiceProvider).getTotalNutrientsForMeal(meal.userId, meal.id!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return buildMealCard(context, ref, mealName, meal, snapshot.data!);
        } else if (snapshot.hasError) {
          return buildErrorCard(context, mealName, snapshot.error.toString());
        } else {
          return buildLoadingCard(context, mealName);
        }
      },
    );
  }

  Widget buildMealCard(BuildContext context, WidgetRef ref, String mealName, meals.Meal meal, Map<String, double> totalNutrients) {
    final subtitle = 'C:${totalNutrients['carbs']?.toStringAsFixed(0)}g P:${totalNutrients['proteins']?.toStringAsFixed(0)}g F:${totalNutrients['fats']?.toStringAsFixed(0)}g, ${totalNutrients['calories']?.toStringAsFixed(0)}Kcal';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: ExpansionTile(
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          collapsedBackgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          title: buildMealTitle(context, mealName, subtitle, meal),
          children: [
            buildFoodList(context, ref, meal),
            ListTile(
              title: Text('Add Food', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.primary)),
              onTap: () {
                navigateToFoodSelector(meal);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMealTitle(BuildContext context, String mealName, String subtitle, meals.Meal meal) {
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
          onSelected: (value) => onMealMenuSelected(value, meal),
          itemBuilder: (BuildContext context) => buildMealPopupMenuItems(),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> buildMealPopupMenuItems() {
    return const [
      PopupMenuItem(value: 'duplicate', child: Text('Duplicate Meal')),
      PopupMenuItem(value: 'delete_all', child: Text('Delete All Foods')),
      PopupMenuItem(value: 'save_as_favorite', child: Text('Save as Favorite')),
      PopupMenuItem(value: 'apply_favorite', child: Text('Apply Favorite')),
    ];
  }

  Widget buildFoodList(BuildContext context, WidgetRef ref, meals.Meal meal) {
    return StreamBuilder<List<macros.Food>>(
      stream: ref.watch(mealsServiceProvider).getFoodsForMealStream(userId: meal.userId, mealId: meal.id!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: snapshot.data!.map((food) => buildFoodItem(context, ref, meal, food)).toList(),
          );
        } else if (snapshot.hasError) {
          return buildErrorTile(context, snapshot.error.toString());
        } else {
          return const ListTile(title: CircularProgressIndicator());
        }
      },
    );
  }

  Widget buildFoodItem(BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    final isSelected = selectedFoods.contains(food.id);

    return GestureDetector(
      onLongPress: () => onFoodLongPress(food.id!),
      onTap: () => onFoodTap(meal, food.id!),
      child: Container(
        color: isSelected ? Colors.grey.withOpacity(0.3) : Colors.transparent,
        child: Slidable(
          key: Key(food.id!),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: buildSlidableStartActions(meal, food),
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: buildSlidableEndActions(ref, meal, food),
          ),
          child: buildFoodListTile(context, food),
        ),
      ),
    );
  }

  List<SlidableAction> buildSlidableStartActions(meals.Meal meal, macros.Food food) {
    return [
      SlidableAction(
        onPressed: (_) => navigateToFoodSelector(meal, food.id),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: Icons.edit,
        label: 'Edit',
      ),
      SlidableAction(
        onPressed: (_) => navigateToFoodSelector(meal),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: Icons.add,
        label: 'Add',
      ),
    ];
  }

  List<SlidableAction> buildSlidableEndActions(WidgetRef ref, meals.Meal meal, macros.Food food) {
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
          if (selectedFoods.isNotEmpty) {
            final mealsList = await getAllMeals(meal.userId);
            await showMoveDialog(ref, mealsList);
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

  ListTile buildFoodListTile(BuildContext context, macros.Food food) {
    return ListTile(
      leading: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onSurface),
      title: Text(food.name, style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(
        'C:${food.carbs.toStringAsFixed(0)}g P:${food.protein.toStringAsFixed(0)}g F:${food.fat.toStringAsFixed(0)}g, ${food.kcal.toStringAsFixed(0)}Kcal',
        style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => onFoodMenuSelected(ref, value, food.id!),
        itemBuilder: (BuildContext context) => buildFoodPopupMenuItems(),
      ),
    );
  }

  List<PopupMenuEntry<String>> buildFoodPopupMenuItems() {
    return const [
      PopupMenuItem(value: 'edit', child: Text('Edit')),
      PopupMenuItem(value: 'delete', child: Text('Delete')),
    ];
  }

  Widget buildAddSnackButton(BuildContext context, WidgetRef ref, String userId, String dailyStatsId, DateTime date, int currentSnacksCount) {
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

  Widget buildError(BuildContext context, String error) {
    return Center(child: Text('Error: $error', style: TextStyle(color: Theme.of(context).colorScheme.onError)));
  }

  Widget buildErrorCard(BuildContext context, String mealName, String error) {
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

  Widget buildLoadingCard(BuildContext context, String mealName) {
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

  Widget buildErrorTile(BuildContext context, String error) {
    return ListTile(
      title: Text('Error: $error', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
    );
  }

  void navigateToFoodSelector(meals.Meal meal, [String? foodId]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodSelector(
          meal: meal,
          myFoodId: foodId,
          isFavoriteMeal: false,
        ),
      ),
    );
  }

  void onMealMenuSelected(String value, meals.Meal meal) async {
    final mealsService = ref.read(mealsServiceProvider);
    if (value == 'duplicate') {
      await showDuplicateDialog(ref, meal);
    } else if (value == 'delete_all') {
      await confirmDeleteAllFoods(ref, meal);
    } else if (value == 'save_as_favorite') {
      final favoriteName = await showFavoriteNameDialog();
      if (favoriteName != null) {
        await mealsService.saveMealAsFavorite(meal.userId, meal.id!, favoriteName: favoriteName, dailyStatsId: meal.dailyStatsId);
      }
    } else if (value == 'apply_favorite') {
      final favoriteMeals = await mealsService.getFavoriteMeals(meal.userId);
      if (favoriteMeals.isNotEmpty) {
        final selectedFavorite = await showSelectFavoriteDialog(favoriteMeals);
        if (selectedFavorite != null) {
          await mealsService.applyFavoriteMealToCurrent(meal.userId, selectedFavorite.id!, meal.id!);
        }
      }
    }
  }

  Future<void> showDuplicateDialog(WidgetRef ref, meals.Meal sourceMeal) async {

    final mealsList = await getAllMeals(sourceMeal.userId);
    final selectedMeal = await showSelectMealDialog(mealsList, 'Select Destination Meal');
    if (selectedMeal != null) {
      final overwriteExisting = await showOverwriteDialog();
      if (overwriteExisting != null) {
        await ref.read(mealsServiceProvider).duplicateMeal(
              userId: sourceMeal.userId,
              sourceMealId: sourceMeal.id!,
              targetMealId: selectedMeal.id!,
              overwriteExisting: overwriteExisting,
            );
      }
    }
  }

  Future<meals.Meal?> showSelectMealDialog(List<meals.Meal> mealsList, String title) {
    return showDialog<meals.Meal>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.roboto()),
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
  }

  Future<meals.Meal?> showSelectFavoriteDialog(List<meals.Meal> favoriteMeals) {
    return showDialog<meals.Meal>(
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
                  title: Text(favMeal.favoriteName ?? favMeal.mealType, style: GoogleFonts.roboto()),
                  onTap: () => Navigator.of(context).pop(favMeal),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool?> showOverwriteDialog() {
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

  Future<void> confirmDeleteAllFoods(WidgetRef ref, meals.Meal meal) async {
    final confirm = await showConfirmationDialog('Delete All Foods', 'Are you sure you want to delete all foods in this meal?');
    if (confirm == true) {
      final mealsService = ref.read(mealsServiceProvider);
      final foods = await mealsService.getFoodsForMeals(userId: meal.userId, mealId: meal.id!);
      for (final food in foods) {
        await mealsService.removeFoodFromMeal(userId: meal.userId, mealId: meal.id!, myFoodId: food.id!);
      }
    }
  }

  Future<void> showMoveDialog(WidgetRef ref, List<meals.Meal> mealsList) async {
    final selectedMeal = await showSelectMealDialog(mealsList, 'Select Destination Meal');
    if (selectedMeal != null) {
      await ref.read(mealsServiceProvider).moveFoods(
            userId: selectedMeal.userId,
            foodIds: selectedFoods,
            targetMealId: selectedMeal.id!,
          );
      if (mounted) {
        setState(() {
          selectedFoods.clear();
          isSelectionMode = false;
        });
      }
    }
  }

  Future<bool?> showConfirmationDialog(String title, String content) {
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

  Future<String?> showFavoriteNameDialog() {
    final TextEditingController nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save as Favorite', style: GoogleFonts.roboto()),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Favorite Name',
              hintText: 'Enter a name for this favorite meal',
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.roboto())),
            TextButton(onPressed: () => Navigator.of(context).pop(nameController.text), child: Text('Save', style: GoogleFonts.roboto())),
          ],
        );
      },
    );
  }

  void onFoodMenuSelected(WidgetRef ref, String value, String foodId) async {
    if (value == 'edit') {
      final userService = ref.read(usersServiceProvider);
      final userId = userService.getCurrentUserId();
      ref.read(mealsServiceProvider);
      final meal = meals.Meal(
        userId: userId,
        dailyStatsId: '',
        date: widget.selectedDate,
        mealType: '',
      );
      navigateToFoodSelector(meal, foodId);
    } else if (value == 'delete') {
      final mealsService = ref.read(mealsServiceProvider);
      await mealsService.removeFoodFromMeal(userId: '', mealId: '', myFoodId: foodId);
    }
  }

  void onFoodLongPress(String foodId) {
    setState(() {
      isSelectionMode = true;
      selectedFoods.add(foodId);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selection mode enabled')));
  }

  void onFoodTap(meals.Meal meal, String foodId) {
    if (isSelectionMode) {
      setState(() {
        if (selectedFoods.contains(foodId)) {
          selectedFoods.remove(foodId);
        } else {
          selectedFoods.add(foodId);
        }
      });
    } else {
      navigateToFoodSelector(meal, foodId);
    }
  }

  Future<List<meals.Meal>> getAllMeals(String userId) async {
    final snapshot = await ref.read(mealsServiceProvider).getUserMealsByDate(userId: userId, date: widget.selectedDate).first;
    return snapshot;
  }
}
