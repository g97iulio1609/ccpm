import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models&Services/meals_model.dart' as meals;
import '../models&Services/meals_services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class FavouritesMeals extends ConsumerWidget {
  const FavouritesMeals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return Scaffold(
 
      body: FutureBuilder<List<meals.Meal>>(
        future: mealsService.getFavoriteMeals(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final favoriteMeals = snapshot.data!;
            if (favoriteMeals.isEmpty) {
              return Center(child: Text('No favourite meals found', style: GoogleFonts.roboto()));
            }
            return ListView.builder(
              itemCount: favoriteMeals.length,
              itemBuilder: (context, index) {
                final meal = favoriteMeals[index];
                return _buildFavoriteMealTile(context, ref, meal);
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onError)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildFavoriteMealTile(BuildContext context, WidgetRef ref, meals.Meal meal) {
    return Slidable(
      key: Key(meal.id!),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final mealsService = ref.read(mealsServiceProvider);
              await mealsService.deleteFavoriteMeal(meal.userId, meal.id!);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favourite meal deleted')));
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        title: Text(meal.favoriteName ?? '', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text('${meal.mealType} - ${meal.date.day}/${meal.date.month}/${meal.date.year}', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => context.push('/mymeals/favorite_meal_detail', extra: meal),
        ),
        onTap: () => context.push('/mymeals/favorite_meal_detail', extra: meal),
      ),
    );
  }
}

class FavouriteDays extends ConsumerWidget {
  const FavouriteDays({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsService = ref.watch(mealsServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: Text('Favourite Days', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<List<meals.FavoriteDay>>(
        future: mealsService.getFavoriteDays(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final favoriteDays = snapshot.data!;
            if (favoriteDays.isEmpty) {
              return Center(child: Text('No favourite days found', style: GoogleFonts.roboto()));
            }
            return ListView.builder(
              itemCount: favoriteDays.length,
              itemBuilder: (context, index) {
                final day = favoriteDays[index];
                return _buildFavoriteDayTile(context, ref, day);
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.onError)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildFavoriteDayTile(BuildContext context, WidgetRef ref, meals.FavoriteDay day) {
    return Slidable(
      key: Key(day.id!),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final mealsService = ref.read(mealsServiceProvider);
              await mealsService.deleteFavoriteDay(day.userId, day.id!);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favourite day deleted')));
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        title: Text(day.favoriteName ?? '', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text('${day.date.day}/${day.date.month}/${day.date.year}', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => context.push('/mydays/favorite_day_detail', extra: day),
        ),
        onTap: () => context.push('/mydays/favorite_day_detail', extra: day),
      ),
    );
  }
}
