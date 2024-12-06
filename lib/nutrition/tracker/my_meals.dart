import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/UI/components/card.dart';
import 'package:alphanessone/UI/components/badge.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/meals_model.dart' as meals;
import '../services/meals_services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class FavouritesMeals extends ConsumerWidget {
  const FavouritesMeals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: FutureBuilder<List<meals.Meal>>(
        future: mealsService.getFavoriteMeals(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final favoriteMeals = snapshot.data!;
            if (favoriteMeals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    Text(
                      'Nessun pasto preferito',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.sm),
                    Text(
                      'I tuoi pasti preferiti appariranno qui',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              itemCount: favoriteMeals.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: AppTheme.spacing.md),
              itemBuilder: (context, index) {
                final meal = favoriteMeals[index];
                return _buildFavoriteMealTile(context, ref, meal);
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  Text(
                    'Errore nel caricamento',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    'Si è verificato un errore: ${snapshot.error}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFavoriteMealTile(
      BuildContext context, WidgetRef ref, meals.Meal meal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Slidable(
      key: Key(meal.id!),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            onPressed: (_) async {
              final mealsService = ref.read(mealsServiceProvider);
              await mealsService.deleteFavoriteMeal(meal.userId, meal.id!);
              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pasto preferito eliminato',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onInverseSurface,
                        ),
                      ),
                      backgroundColor: colorScheme.inverseSurface,
                    ),
                  );
                });
              }
            },
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, size: 20),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  'Elimina',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: AppCard(
        onTap: () => _navigateToMealDetail(context, meal),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.lg),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppTheme.spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.favoriteName ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.xs),
                    Row(
                      children: [
                        AppBadge(
                          label: meal.mealType,
                          variant: AppBadgeVariant.gradient,
                          status: AppBadgeStatus.info,
                          size: AppBadgeSize.small,
                        ),
                        SizedBox(width: AppTheme.spacing.sm),
                        AppBadge(
                          label:
                              '${meal.date.day}/${meal.date.month}/${meal.date.year}',
                          variant: AppBadgeVariant.gradient,
                          status: AppBadgeStatus.success,
                          icon: Icons.calendar_today,
                          size: AppBadgeSize.small,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Modifica',
                icon: Icons.edit_outlined,
                onPressed: () => _navigateToMealDetail(context, meal),
                variant: AppButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMealDetail(BuildContext context, meals.Meal meal) {
    context
        .push('/mymeals/favorite_meal_detail', extra: {'meal': meal.toMap()});
  }
}

class FavouriteDays extends ConsumerWidget {
  const FavouriteDays({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Giorni Preferiti',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<List<meals.FavoriteDay>>(
        future: mealsService.getFavoriteDays(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final favoriteDays = snapshot.data!;
            if (favoriteDays.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    Text(
                      'Nessun giorno preferito',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.sm),
                    Text(
                      'I tuoi giorni preferiti appariranno qui',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              itemCount: favoriteDays.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: AppTheme.spacing.md),
              itemBuilder: (context, index) {
                final day = favoriteDays[index];
                return _buildFavoriteDayTile(context, ref, day);
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  Text(
                    'Errore nel caricamento',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    'Si è verificato un errore: ${snapshot.error}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFavoriteDayTile(
      BuildContext context, WidgetRef ref, meals.FavoriteDay day) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Slidable(
      key: Key(day.id!),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            onPressed: (_) async {
              final mealsService = ref.read(mealsServiceProvider);
              await mealsService.deleteFavoriteDay(day.userId, day.id!);
              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Giorno preferito eliminato',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onInverseSurface,
                        ),
                      ),
                      backgroundColor: colorScheme.inverseSurface,
                    ),
                  );
                });
              }
            },
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, size: 20),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  'Elimina',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: AppCard(
        onTap: () => _navigateToDayDetail(context, day),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.lg),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: colorScheme.secondary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppTheme.spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.favoriteName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.xs),
                    AppBadge(
                      label:
                          '${day.date.day}/${day.date.month}/${day.date.year}',
                      variant: AppBadgeVariant.gradient,
                      status: AppBadgeStatus.success,
                      icon: Icons.calendar_today,
                      size: AppBadgeSize.small,
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Modifica',
                icon: Icons.edit_outlined,
                onPressed: () => _navigateToDayDetail(context, day),
                variant: AppButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDayDetail(BuildContext context, meals.FavoriteDay day) {
    context.push('/mydays/favorite_day_detail', extra: {'day': day.toMap()});
  }
}
