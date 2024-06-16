import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:alphanessone/nutrition/models&Services/meals_model.dart' as meals;
import 'package:alphanessone/nutrition/models&Services/meals_services.dart';

class CustomAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.userRole,
    required this.controller,
    required this.isLargeScreen,
  });

  final String userRole;
  final TrainingProgramController controller;
  final bool isLargeScreen;

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);
  }

String _getTitleForRoute(BuildContext context) {
  final String currentPath = GoRouterState.of(context).uri.toString();

  switch (currentPath) {
    case '/programs_screen':
      return 'I Miei Allenamenti';
    case '/exercises_list':
      return 'Esercizi';
    case '/maxrmdashboard':
      return 'Massimali';
    case '/user_profile':
      return 'Profilo Utente';
    case '/training_program':
      return 'Programma di Allenamento';
    case '/users_dashboard':
      return 'Gestione Utenti';
    case '/volume_dashboard':
      return 'Volume Allenamento';
    case '/user_programs':
      return 'Programmi Utente';
    case '/measurements':
      return 'Misurazioni Antropometriche';
    case '/tdee':
      return 'Fabbisogno Calorico';
    case '/macros_selector':
      return 'Calcolatore Macronutrienti';
    case '/training_gallery':
      return 'Galleria Allenamenti';
    case '/food_tracker':
      return 'Tracciatore Cibo';
    default:
      return 'Alphaness One';
  }
}

bool _isTrainingProgramRoute(BuildContext context) {
  final currentRoute = GoRouterState.of(context).uri.toString();
  return currentRoute.startsWith('/programs_screen/user_programs/') &&
      (currentRoute.contains('/training_program/') ||
          currentRoute.contains('/week/'));
}


  bool _isDailyFoodTrackerRoute(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    return currentRoute == '/food_tracker';
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE d MMMM y', 'it_IT');
    return formatter.format(date);
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: 'client');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a role';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await ref.read(usersServiceProvider).createUser(
                        name: nameController.text,
                        email: emailController.text,
                        password: passwordController.text,
                        role: roleController.text,
                      );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDayMenuSelected(BuildContext context, WidgetRef ref, String value) async {
    final mealsService = ref.read(mealsServiceProvider);
    final userService = ref.read(usersServiceProvider);
    final userId = userService.getCurrentUserId();
    final selectedDate = ref.watch(selectedDateProvider);

    if (value == 'save_as_favorite_day') {
      final favoriteName = await _showFavoriteNameDialog(context);
      if (favoriteName != null) {
        await mealsService.saveDayAsFavorite(userId, selectedDate, favoriteName: favoriteName);
      }
    } else if (value == 'apply_favorite_day') {
      final favoriteDays = await mealsService.getFavoriteDays(userId);
      if (favoriteDays.isNotEmpty) {
        final selectedFavorite = await showDialog<meals.FavoriteDay>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Select Favorite Day', style: TextStyle(fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: favoriteDays.length,
                  itemBuilder: (BuildContext context, int index) {
                    final favDay = favoriteDays[index];
                    return ListTile(
                      title: Text(favDay.favoriteName ?? 'Favorite Day', style: const TextStyle(fontSize: 14)),
                      onTap: () => Navigator.of(context).pop(favDay),
                    );
                  },
                ),
              ),
            );
          },
        );

        if (selectedFavorite != null) {
          await mealsService.applyFavoriteDayToCurrent(userId, selectedFavorite.id!, selectedDate);
        }
      }
    }
  }

  Future<String?> _showFavoriteNameDialog(BuildContext context) {
    final TextEditingController _nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save as Favorite', style: TextStyle(fontSize: 16)),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Favorite Name',
              hintText: 'Enter a name for this favorite day',
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(_nameController.text), child: const Text('Save')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isBackButtonVisible = currentRoute.split('/').length > 2;
    final selectedDate = ref.watch(selectedDateProvider);

    return AppBar(
      centerTitle: true,
      title: _isDailyFoodTrackerRoute(context)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).update((state) => state.subtract(const Duration(days: 1)));
                  },
                ),
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).update((state) => state.add(const Duration(days: 1)));
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _onDayMenuSelected(context, ref, value),
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'save_as_favorite_day', child: Text('Save as Favorite Day')),
                    const PopupMenuItem(value: 'apply_favorite_day', child: Text('Apply Favorite Day')),
                  ],
                ),
              ],
            )
          : Text(_getTitleForRoute(context)),
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onBackground,
      leading: isBackButtonVisible
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: IconButton(
                    iconSize: 24,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      context.pop();
                    },
                  ),
                ),
                if (!widget.isLargeScreen)
                  Flexible(
                    child: IconButton(
                      iconSize: 24,
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
              ],
            )
          : null,
      actions: [
        if (widget.userRole == 'admin' && currentRoute == '/users_dashboard')
          IconButton(
            onPressed: () => _showAddUserDialog(context, ref),
            icon: const Icon(Icons.person_add),
          ),
        if (_isTrainingProgramRoute(context))
          IconButton(
            onPressed: () => widget.controller.submitProgram(context),
            icon: const Icon(Icons.save),
          ),
      ],
    );
  }
}

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
