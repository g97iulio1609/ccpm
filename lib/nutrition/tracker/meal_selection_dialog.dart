import 'package:alphanessone/nutrition/models/meals_model.dart';
import 'package:alphanessone/nutrition/services/meals_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MealSelectionDialog extends ConsumerStatefulWidget {
  final String userId;
  final List<String> initialSelectedMealIds;

  const MealSelectionDialog({
    required this.userId,
    this.initialSelectedMealIds = const [],
    super.key
  });

  @override
  ConsumerState<MealSelectionDialog> createState() => _MealSelectionDialogState();
}

class _MealSelectionDialogState extends ConsumerState<MealSelectionDialog> {
  List<String> _selectedMealIds = [];
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _selectedMealIds = List.from(widget.initialSelectedMealIds);
  }

  @override
  Widget build(BuildContext context) {
    final mealsService = ref.watch(mealsServiceProvider);

    return AlertDialog(
      title: Text('Select Meals', style: GoogleFonts.roboto()),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('All Meals', style: GoogleFonts.roboto()),
                Switch(
                  value: _showFavorites,
                  onChanged: (value) {
                    setState(() {
                      _showFavorites = value;
                    });
                  },
                ),
                Text('Favorites', style: GoogleFonts.roboto()),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Meal>>(
                stream: _showFavorites
                    ? _getFavoriteMeals()
                    : _getAllMeals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading meals', style: GoogleFonts.roboto()));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No meals found', style: GoogleFonts.roboto()));
                  } else {
                    final meals = snapshot.data!;
                    return ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        final isSelected = _selectedMealIds.contains(meal.id);
                        return CheckboxListTile(
                          title: Text(meal.mealType, style: GoogleFonts.roboto()),
                          subtitle: Text('Calories: ${meal.totalCalories} kcal', style: GoogleFonts.roboto()),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedMealIds.add(meal.id!);
                              } else {
                                _selectedMealIds.remove(meal.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.roboto()),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedMealIds);
          },
          child: Text('Select', style: GoogleFonts.roboto()),
        ),
      ],
    );
  }

  Stream<List<Meal>> _getAllMeals() {
    return ref
        .read(mealsServiceProvider)
        .getUserMealsByDate(userId: widget.userId, date: DateTime.now())
        .map((meals) => meals.where((meal) => !meal.isFavorite).toList());
  }

  Stream<List<Meal>> _getFavoriteMeals() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('meals')
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList());
  }
}