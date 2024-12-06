import 'package:alphanessone/nutrition/models/meals_model.dart';
import 'package:alphanessone/nutrition/services/meals_services.dart';
import 'package:alphanessone/UI/components/dialog.dart';
import 'package:alphanessone/UI/components/badge.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MealSelectionDialog extends ConsumerStatefulWidget {
  final String userId;
  final List<String> initialSelectedMealIds;

  const MealSelectionDialog(
      {required this.userId,
      this.initialSelectedMealIds = const [],
      super.key});

  @override
  ConsumerState<MealSelectionDialog> createState() =>
      _MealSelectionDialogState();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: 'Seleziona i Pasti',
      subtitle: 'Scegli i pasti da aggiungere al tuo diario',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          Icons.restaurant_menu,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      maxWidth: 480,
      maxHeight: MediaQuery.of(context).size.height * 0.8,
      actions: [
        AppDialog.buildCancelButton(context: context),
        AppDialog.buildActionButton(
          context: context,
          label: 'Seleziona',
          onPressed: () => Navigator.of(context).pop(_selectedMealIds),
          icon: Icons.check_circle_outline,
        ),
      ],
      children: [
        // Filter Toggle
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.lg,
            vertical: AppTheme.spacing.md,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tutti i Pasti',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: !_showFavorites
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      !_showFavorites ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Switch(
                value: _showFavorites,
                onChanged: (value) => setState(() => _showFavorites = value),
                activeColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withOpacity(0.2),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Text(
                'Preferiti',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _showFavorites
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      _showFavorites ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),

        // Meals List
        SizedBox(
          height: 400,
          child: StreamBuilder<List<Meal>>(
            stream: _showFavorites ? _getFavoriteMeals() : _getAllMeals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 48,
                      ),
                      SizedBox(height: AppTheme.spacing.md),
                      Text(
                        'Errore nel caricamento dei pasti',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.no_meals,
                        color: colorScheme.onSurfaceVariant,
                        size: 48,
                      ),
                      SizedBox(height: AppTheme.spacing.md),
                      Text(
                        'Nessun pasto trovato',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final meals = snapshot.data!;
              return ListView.separated(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                itemCount: meals.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: AppTheme.spacing.sm),
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  final isSelected = _selectedMealIds.contains(meal.id);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMealIds.remove(meal.id);
                          } else {
                            _selectedMealIds.add(meal.id!);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      child: Container(
                        padding: EdgeInsets.all(AppTheme.spacing.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withOpacity(0.1)
                              : colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radii.lg),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacing.sm),
                              decoration: BoxDecoration(
                                color: (isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest)
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radii.md),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.restaurant,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.mealType,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: AppTheme.spacing.xs),
                                  Row(
                                    children: [
                                      AppBadge(
                                        label: '${meal.totalCalories} kcal',
                                        variant: AppBadgeVariant.gradient,
                                        status: AppBadgeStatus.primary,
                                        size: AppBadgeSize.small,
                                      ),
                                      if (meal.isFavorite) ...[
                                        SizedBox(width: AppTheme.spacing.sm),
                                        const AppBadge(
                                          label: 'Preferito',
                                          variant: AppBadgeVariant.gradient,
                                          status: AppBadgeStatus.info,
                                          icon: Icons.favorite,
                                          size: AppBadgeSize.small,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
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
        .map((snapshot) =>
            snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList());
  }
}
