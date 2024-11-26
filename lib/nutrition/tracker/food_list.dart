import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/macros_model.dart' as macros;
import '../models/meals_model.dart' as meals;
import '../services/meals_services.dart';
import 'food_selector.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodList extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final String? userId;

  const FoodList({
    required this.selectedDate,
    this.userId,
    super.key,
  });

  @override
  FoodListState createState() => FoodListState();
}

class FoodListState extends ConsumerState<FoodList> {
  final List<String> selectedFoods = [];
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.userId != null) {
      final mealsService = ref.read(mealsServiceProvider);
      await mealsService.createDailyStatsIfNotExist(
          widget.userId!, widget.selectedDate);
      await mealsService.createMealsIfNotExist(
          widget.userId!, widget.selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userId = widget.userId;
    final theme = Theme.of(context);

    if (userId == null) {
      return Center(
        child: Text(
          'Seleziona un utente',
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    return StreamBuilder<List<meals.Meal>>(
      stream: mealsService.getUserMealsByDate(
          userId: userId, date: widget.selectedDate),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final mealsList = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  buildMealSections(context, ref, mealsList, userId),
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return buildError(context, snapshot.error.toString());
        } else {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
      },
    );
  }

  List<Widget> buildMealSections(BuildContext context, WidgetRef ref,
      List<meals.Meal> mealsList, String userId) {
    final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
    List<Widget> mealSections = [];

    // Aggiungi padding iniziale
    mealSections.add(const SizedBox(height: 8));

    // Aggiungi i pasti principali
    mealSections.addAll(mealTypes.map((mealType) => buildMealSection(context,
        ref, mealType, getMealByType(mealsList, mealType, userId), mealsList)));

    // Aggiungi gli snack
    final snackMeals = getSnackMeals(mealsList);
    mealSections.addAll(snackMeals.map((snack) => buildMealSection(context, ref,
        'Snack ${snackMeals.indexOf(snack) + 1}', snack, mealsList)));

    // Aggiungi il pulsante per aggiungere snack
    mealSections.add(buildAddSnackButton(
        context,
        ref,
        userId,
        mealsList.isNotEmpty ? mealsList.first.dailyStatsId : '',
        widget.selectedDate,
        snackMeals.length));

    return mealSections;
  }

  meals.Meal getMealByType(
      List<meals.Meal> mealsList, String mealType, String userId) {
    return mealsList.firstWhere((meal) => meal.mealType == mealType,
        orElse: () => meals.Meal.emptyMeal(
            userId,
            mealsList.isNotEmpty ? mealsList.first.dailyStatsId : '',
            widget.selectedDate,
            mealType));
  }

  List<meals.Meal> getSnackMeals(List<meals.Meal> mealsList) {
    return mealsList
        .where((meal) => meal.mealType.startsWith('Snack'))
        .toList();
  }

  Widget buildMealSection(BuildContext context, WidgetRef ref, String mealName,
      meals.Meal meal, List<meals.Meal> mealsList) {
    if (meal.id == null) {
      return buildErrorCard(context, mealName, 'Meal data is not available.');
    }

    return FutureBuilder<Map<String, double>>(
      future: ref
          .watch(mealsServiceProvider)
          .getTotalNutrientsForMeal(meal.userId, meal.id!),
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

  Widget buildMealCard(BuildContext context, WidgetRef ref, String mealName,
      meals.Meal meal, Map<String, double> totalNutrients) {
    final theme = Theme.of(context);
    final subtitle =
        'C:${totalNutrients['carbs']?.toStringAsFixed(0)}g P:${totalNutrients['proteins']?.toStringAsFixed(0)}g F:${totalNutrients['fats']?.toStringAsFixed(0)}g';
    final calories = '${totalNutrients['calories']?.toStringAsFixed(0)} Kcal';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: theme.colorScheme.surface,
            collapsedBackgroundColor: theme.colorScheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mealName,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      calories,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () =>
                      showFoodSelectorBottomSheet(context, ref, meal),
                  tooltip: 'Aggiungi Alimento',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => onMealMenuSelected(value, meal),
                  itemBuilder: (BuildContext context) =>
                      buildMealPopupMenuItems(),
                ),
              ],
            ),
            children: [
              buildFoodList(context, ref, meal),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFoodList(BuildContext context, WidgetRef ref, meals.Meal meal) {
    return StreamBuilder<List<macros.Food>>(
      stream: ref
          .watch(mealsServiceProvider)
          .getFoodsForMealStream(userId: meal.userId, mealId: meal.id!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return ListTile(
              title: Text('No foods added.',
                  style: GoogleFonts.roboto(
                      color: Theme.of(context).colorScheme.onSurface)),
            );
          }
          return Column(
            children: snapshot.data!
                .map((food) => buildFoodItem(context, ref, meal, food))
                .toList(),
          );
        } else if (snapshot.hasError) {
          return buildErrorTile(context, snapshot.error.toString());
        } else {
          return const ListTile(title: CircularProgressIndicator());
        }
      },
    );
  }

  Widget buildFoodItem(
      BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    final theme = Theme.of(context);
    final isSelected = selectedFoods.contains(food.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: GestureDetector(
        onLongPress: () => onFoodLongPress(food.id!),
        onTap: () => onFoodTap(context, ref, meal, food.id!),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Slidable(
            key: Key(food.id!),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: buildSlidableStartActions(context, ref, meal, food),
            ),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: buildSlidableEndActions(ref, meal, food),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                food.name,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'C:${food.carbs.toStringAsFixed(0)}g P:${food.protein.toStringAsFixed(0)}g F:${food.fat.toStringAsFixed(0)}g\n${food.kcal.toStringAsFixed(0)} Kcal',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    showFoodOptionsBottomSheet(context, ref, meal, food),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<SlidableAction> buildSlidableStartActions(
      BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    return [
      SlidableAction(
        onPressed: (_) =>
            showFoodSelectorBottomSheet(context, ref, meal, myFoodId: food.id),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: Icons.edit,
        label: 'Edit',
      ),
      SlidableAction(
        onPressed: (_) => showFoodSelectorBottomSheet(context, ref, meal),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: Icons.add,
        label: 'Add',
      ),
    ];
  }

  List<SlidableAction> buildSlidableEndActions(
      WidgetRef ref, meals.Meal meal, macros.Food food) {
    final mealsService = ref.read(mealsServiceProvider);

    return [
      SlidableAction(
        onPressed: (_) async => await mealsService.removeFoodFromMeal(
            userId: meal.userId, mealId: meal.id!, myFoodId: food.id!),
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
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No foods selected')));
          }
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: Icons.move_to_inbox,
        label: 'Move',
      ),
    ];
  }

  Widget buildError(BuildContext context, String error) {
    return Center(
        child: Text('Error: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error)));
  }

  Widget buildErrorCard(BuildContext context, String mealName, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: ExpansionTile(
          title: Text(mealName,
              style: GoogleFonts.roboto(
                  color: Theme.of(context).colorScheme.onSurface)),
          children: [
            ListTile(
                title: Text('Error: $error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)))
          ],
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
          title: Text(mealName,
              style: GoogleFonts.roboto(
                  color: Theme.of(context).colorScheme.onSurface)),
          children: const [ListTile(title: CircularProgressIndicator())],
        ),
      ),
    );
  }

  Widget buildErrorTile(BuildContext context, String error) {
    return ListTile(
      title: Text('Error: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
      if (favoriteName != null && favoriteName.trim().isNotEmpty) {
        await mealsService.saveMealAsFavorite(meal.userId, meal.id!,
            favoriteName: favoriteName.trim(), dailyStatsId: meal.dailyStatsId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorite name cannot be empty')));
      }
    } else if (value == 'apply_favorite') {
      final favoriteMeals = await mealsService.getFavoriteMeals(meal.userId);
      if (favoriteMeals.isNotEmpty) {
        final selectedFavorite = await showSelectFavoriteDialog(favoriteMeals);
        if (selectedFavorite != null) {
          await mealsService.applyFavoriteMealToCurrent(
              meal.userId, selectedFavorite.id!, meal.id!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No favorite meals available')));
      }
    }
  }

  Future<void> showDuplicateDialog(WidgetRef ref, meals.Meal sourceMeal) async {
    final mealsList = await getAllMeals(sourceMeal.userId);
    final selectedMeal =
        await showSelectMealDialog(mealsList, 'Select Destination Meal');
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

  Future<meals.Meal?> showSelectMealDialog(
      List<meals.Meal> mealsList, String title) {
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
                  title: Text(favMeal.favoriteName ?? favMeal.mealType,
                      style: GoogleFonts.roboto()),
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
          content: Text(
              'Do you want to overwrite existing foods in the selected meal or add the new foods to it?',
              style: GoogleFonts.roboto()),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Add to Existing', style: GoogleFonts.roboto())),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Overwrite', style: GoogleFonts.roboto())),
          ],
        );
      },
    );
  }

  Future<void> confirmDeleteAllFoods(WidgetRef ref, meals.Meal meal) async {
    final confirm = await showConfirmationDialog('Delete All Foods',
        'Are you sure you want to delete all foods in this meal?');
    if (confirm == true) {
      final mealsService = ref.read(mealsServiceProvider);
      final foods = await mealsService.getFoodsForMeals(
          userId: meal.userId, mealId: meal.id!);
      for (final food in foods) {
        await mealsService.removeFoodFromMeal(
            userId: meal.userId, mealId: meal.id!, myFoodId: food.id!);
      }
    }
  }

  Future<void> showMoveDialog(WidgetRef ref, List<meals.Meal> mealsList) async {
    final selectedMeal =
        await showSelectMealDialog(mealsList, 'Select Destination Meal');
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foods moved successfully')));
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
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: GoogleFonts.roboto())),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: GoogleFonts.roboto())),
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
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: GoogleFonts.roboto())),
            TextButton(
                onPressed: () => Navigator.of(context).pop(nameController.text),
                child: Text('Save', style: GoogleFonts.roboto())),
          ],
        );
      },
    );
  }

  void onFoodMenuSelected(
      WidgetRef ref, String value, String foodId, meals.Meal meal) async {
    final mealsService = ref.read(mealsServiceProvider);
    if (value == 'edit') {
      showFoodSelectorBottomSheet(context, ref, meal, myFoodId: foodId);
    } else if (value == 'delete') {
      final confirm = await showConfirmationDialog(
          'Delete Food', 'Are you sure you want to delete this food?');
      if (confirm == true) {
        await mealsService.removeFoodFromMeal(
            userId: meal.userId, mealId: meal.id!, myFoodId: foodId);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food deleted successfully')));
      }
    } else if (value == 'move') {
      setState(() {
        if (selectedFoods.contains(foodId)) {
          selectedFoods.remove(foodId);
        } else {
          selectedFoods.add(foodId);
        }
        isSelectionMode = true;
      });
      if (selectedFoods.isNotEmpty) {
        final mealsList = await getAllMeals(meal.userId);
        await showMoveDialog(ref, mealsList);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No foods selected')));
      }
    }
  }

  void onFoodLongPress(String foodId) {
    setState(() {
      isSelectionMode = true;
      if (!selectedFoods.contains(foodId)) {
        selectedFoods.add(foodId);
      }
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Selection mode enabled')));
  }

  void onFoodTap(
      BuildContext context, WidgetRef ref, meals.Meal meal, String foodId) {
    if (isSelectionMode) {
      setState(() {
        if (selectedFoods.contains(foodId)) {
          selectedFoods.remove(foodId);
          if (selectedFoods.isEmpty) {
            isSelectionMode = false;
          }
        } else {
          selectedFoods.add(foodId);
        }
      });
    } else {
      showFoodSelectorBottomSheet(context, ref, meal, myFoodId: foodId);
    }
  }

  Future<List<meals.Meal>> getAllMeals(String userId) async {
    final snapshot = await ref
        .read(mealsServiceProvider)
        .getUserMealsByDate(userId: userId, date: widget.selectedDate)
        .first;
    return snapshot;
  }

  void showFoodSelectorBottomSheet(
      BuildContext context, WidgetRef ref, meals.Meal meal,
      {String? myFoodId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Mantiene il modale a metà schermo
      backgroundColor: Colors.transparent, // Rende lo sfondo trasparente
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: FoodSelector(
            meal: meal,
            myFoodId: myFoodId,
            onSave: () {
              setState(() {});
            },
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  void showFoodOptionsBottomSheet(
      BuildContext context, WidgetRef ref, meals.Meal meal, macros.Food food) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('Modifica', style: GoogleFonts.roboto()),
                onTap: () {
                  Navigator.pop(context);
                  showFoodSelectorBottomSheet(context, ref, meal,
                      myFoodId: food.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text('Elimina', style: GoogleFonts.roboto()),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showConfirmationDialog(
                      'Elimina Alimento',
                      'Sei sicuro di voler eliminare questo alimento?');
                  if (confirm == true) {
                    await ref.read(mealsServiceProvider).removeFoodFromMeal(
                        userId: meal.userId,
                        mealId: meal.id!,
                        myFoodId: food.id!);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.move_to_inbox),
                title: Text('Sposta', style: GoogleFonts.roboto()),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    selectedFoods.clear();
                    selectedFoods.add(food.id!);
                    isSelectionMode = true;
                  });
                  final mealsList = await getAllMeals(meal.userId);
                  await showMoveDialog(ref, mealsList);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> buildMealPopupMenuItems() {
    return [
      PopupMenuItem(value: 'duplicate', child: Text('Duplica Pasto')),
      PopupMenuItem(
          value: 'delete_all', child: Text('Elimina Tutti gli Alimenti')),
      PopupMenuItem(
          value: 'save_as_favorite', child: Text('Salva come Preferito')),
      PopupMenuItem(value: 'apply_favorite', child: Text('Applica Preferito')),
    ];
  }

  Widget buildAddSnackButton(BuildContext context, WidgetRef ref, String userId,
      String dailyStatsId, DateTime date, int currentSnacksCount) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          if (dailyStatsId.isNotEmpty) {
            final mealsService = ref.read(mealsServiceProvider);
            await mealsService.createSnack(
                userId: userId, dailyStatsId: dailyStatsId, date: date);
          }
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text(
              'Aggiungi Snack ${currentSnacksCount + 1}',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
