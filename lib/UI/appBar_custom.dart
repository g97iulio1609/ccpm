// appBar_custom.dart

import 'package:alphanessone/Viewer/providers/training_program_provider.dart';
import 'package:alphanessone/exerciseManager/exercises_manager.dart';
import 'package:alphanessone/ExerciseRecords/maxrmdashboard.dart';
import 'package:alphanessone/measurements/measurements.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:alphanessone/nutrition/models/meals_model.dart' as meals;
import 'package:alphanessone/nutrition/services/meals_services.dart';
import 'package:alphanessone/Viewer/UI/exercise_details.dart';
import 'package:alphanessone/nutrition/models/diet_plan_model.dart';
import 'package:alphanessone/nutrition/services/diet_plan_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alphanessone/Store/inAppPurchase_services.dart'; // Import aggiunto

class CustomAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.userRole,
    this.controller,
    required this.isLargeScreen,
    this.onAddMeasurement,
  });

  final String userRole;
  final TrainingProgramController? controller;
  final bool isLargeScreen;
  final VoidCallback? onAddMeasurement;

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  late final InAppPurchaseService _inAppPurchaseService;
  bool _syncing = false; // Stato di caricamento per sincronizzazione

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);
    _inAppPurchaseService = InAppPurchaseService();
    // Inizializzazione se necessario
  }

  String _getTitleForRoute(String currentPath) {
    if (currentPath.contains('/exercise_details/')) {
      return ref.watch(currentExerciseNameProvider);
    } else if (currentPath.contains('/workout_details/')) {
      return ref.watch(currentWorkoutNameProvider);
    } else if (currentPath.contains('/week_details/')) {
      return ref.watch(currentWeekNameProvider);
    }

    switch (currentPath) {
      case '/programs_screen':
        return 'Coaching';
      case '/user_programs':
        return 'I Miei Allenamenti';
      case '/exercises_list':
        return 'Esercizi';
      case '/subscriptions':
        return 'Abbonamenti';
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
      case '/measurements':
        return 'Misurazioni';
      case '/tdee':
        return 'Fabbisogno Calorico';
      case '/macros_selector':
        return 'Calcolatore Macronutrienti';
      case '/training_gallery':
        return 'Galleria Allenamenti';
      case '/food_tracker':
        return 'Tracciatore Cibo';
      case '/food_tracker/diet_plan':
        return 'Aggiungi Piano Dietetico';
      case '/food_tracker/view_diet_plans':
        return 'Visualizza Piani Dietetici';
      default:
        return 'Alphaness One';
    }
  }

  bool _isTrainingProgramRoute(String currentRoute) {
    return currentRoute.startsWith('/user_programs/') &&
        (currentRoute.contains('/training_program/') ||
            currentRoute.contains('/week/'));
  }

  bool _isDailyFoodTrackerRoute(String currentRoute) {
    return currentRoute == '/food_tracker';
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE d MMMM y', 'it_IT');
    return formatter.format(date);
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: 'client');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext dialogContext) {
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop({
                    'name': nameController.text,
                    'email': emailController.text,
                    'password': passwordController.text,
                    'role': roleController.text,
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final usersService = ref.read(usersServiceProvider);
      await usersService.createUser(
        name: result['name']!,
        email: result['email']!,
        password: result['password']!,
        role: result['role']!,
      );
    }
  }

  Future<void> _onDayMenuSelected(String value) async {
    if (!mounted) return;

    final mealsService = ref.read(mealsServiceProvider);
    final userService = ref.read(usersServiceProvider);
    final userId = userService.getCurrentUserId();
    final selectedDate = ref.read(selectedDateProvider);

    if (value == 'save_as_favorite_day') {
      final favoriteName = await _showFavoriteNameDialog();
      if (favoriteName != null && mounted) {
        await mealsService.saveDayAsFavorite(userId, selectedDate, favoriteName: favoriteName);
      }
    } else if (value == 'apply_favorite_day') {
      final favoriteDays = await mealsService.getFavoriteDays(userId);
      if (favoriteDays.isNotEmpty && mounted) {
        final selectedFavorite = await _showFavoriteDaySelectionDialog(favoriteDays);
        if (selectedFavorite != null && mounted) {
          await mealsService.applyFavoriteDayToCurrent(userId, selectedFavorite.id!, selectedDate);
        }
      }
    } else if (value == 'add_diet_plan') {
      context.go('/food_tracker/diet_plan');
    } else if (value == 'view_diet_plans') {
      context.go('/food_tracker/view_diet_plans');
    }
  }

  Future<String?> _showFavoriteNameDialog() {
    final TextEditingController nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Save as Favorite', style: TextStyle(fontSize: 16)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Favorite Name',
              hintText: 'Enter a name for this favorite day',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(nameController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<meals.FavoriteDay?> _showFavoriteDaySelectionDialog(List<meals.FavoriteDay> favoriteDays) {
    return showDialog<meals.FavoriteDay>(
      context: context,
      builder: (BuildContext dialogContext) {
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
                  title: Text(favDay.favoriteName, style: const TextStyle(fontSize: 14)),
                  onTap: () => Navigator.of(dialogContext).pop(favDay),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncProducts() async {
    setState(() {
      _syncing = true;
    });
    try {
      await _inAppPurchaseService.manualSyncProducts();
      _showSnackBar('Products synced successfully');
    } catch (e) {
      _showSnackBar('Errore durante la sincronizzazione dei prodotti: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _syncing = true;
    });
    try {
      await _inAppPurchaseService.initStoreInfo();
      _showSnackBar('Store info initialized successfully');
    } catch (e) {
      _showSnackBar('Errore durante l\'inizializzazione dello store: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isBackButtonVisible = currentRoute.split('/').length > 2;
    final selectedDate = ref.watch(selectedDateProvider);
    final isAdmin = widget.userRole == 'admin';

    return AppBar(
      centerTitle: true,
      title: _isDailyFoodTrackerRoute(currentRoute)
          ? _buildDateSelector(selectedDate)
          : Text(_getTitleForRoute(currentRoute)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      leading: isBackButtonVisible ? _buildLeadingButtons(currentRoute) : null,
      actions: _buildActions(currentRoute, isAdmin),
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  Widget _buildDateSelector(DateTime selectedDate) {
    return Row(
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
          onSelected: _onDayMenuSelected,
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(value: 'save_as_favorite_day', child: Text('Save as Favorite Day')),
            const PopupMenuItem(value: 'apply_favorite_day', child: Text('Apply Favorite Day')),
            const PopupMenuItem(value: 'add_diet_plan', child: Text('Add Diet Plan')),
            const PopupMenuItem(value: 'view_diet_plans', child: Text('View Diet Plans')),
          ],
        ),
      ],
    );
  }

  Widget _buildLeadingButtons(String currentRoute) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: IconButton(
            iconSize: 24,
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (currentRoute.startsWith('/user_programs/') &&
                  ref.read(previousRouteProvider) == '/programs_screen') {
                context.go('/programs_screen');
              } else if ((context).canPop()) {
                context.pop();
              }
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
    );
  }

  List<Widget> _buildActions(String currentRoute, bool isAdmin) {
    final List<Widget> actions = [];

    // Azioni esistenti
    if (widget.userRole == 'admin' && currentRoute == '/users_dashboard') {
      actions.add(
        IconButton(
          onPressed: () => _showAddUserDialog(context),
          icon: const Icon(Icons.person_add),
        ),
      );
    }

    if (_isTrainingProgramRoute(currentRoute)) {
      actions.add(
        IconButton(
          onPressed: () {
            widget.controller?.submitProgram(context);
          },
          icon: const Icon(Icons.save),
        ),
      );
    }

    if (currentRoute == '/measurements') {
      actions.add(
        IconButton(
          onPressed: () {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              MeasurementsPage.showAddMeasurementDialog(context, ref, userId);
            }
          },
          icon: const Icon(Icons.add),
        ),
      );
    }

    if (currentRoute == '/maxrmdashboard') {
      actions.add(
        IconButton(
          onPressed: () {
            MaxRMDashboard.showAddMaxRMDialog(context, ref);
          },
          icon: const Icon(Icons.add),
        ),
      );
    }

    if (currentRoute == '/exercises_list') {
      actions.add(
        IconButton(
          onPressed: () {
            ExercisesManager.showAddExerciseBottomSheet(context, ref);
          },
          icon: const Icon(Icons.add),
        ),
      );
    }

    if (currentRoute == '/food_tracker/view_diet_plans') {
      actions.add(
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'apply_template') {
              final templateDietPlan = await _selectTemplate(context);
              if (templateDietPlan != null) {
                final newDietPlan = templateDietPlan.copyWith(
                  id: null,
                  startDate: DateTime.now(),
                );
                final dietPlanId = await ref.read(dietPlanServiceProvider).createDietPlan(newDietPlan);
                final createdDietPlan = newDietPlan.copyWith(id: dietPlanId);
                await ref.read(dietPlanServiceProvider).applyDietPlan(createdDietPlan);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template Applied as New Diet Plan')));
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'apply_template', child: Text('Apply Template')),
          ],
        ),
      );
    }

    // Azioni aggiunte per InAppPurchasePage
    if (currentRoute == '/subscriptions') {
      if (isAdmin) {
        actions.add(
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _syncing ? null : _syncProducts,
            tooltip: 'Sync Products',
          ),
        );
      }
      actions.add(
        IconButton(
          icon: _syncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh),
          onPressed: _syncing ? null : _initialize,
          tooltip: 'Refresh',
        ),
      );
    }

    return actions;
  }

  Future<DietPlan?> _selectTemplate(BuildContext context) async {
    final userService = ref.read(usersServiceProvider);
    final adminId = userService.getCurrentUserId();
    final templates = await ref.read(dietPlanServiceProvider).getDietPlanTemplatesStream(adminId).first;

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No templates available')));
      return null;
    }

    return showDialog<DietPlan>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Template', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  title: Text(template.name, style: GoogleFonts.roboto()),
                  subtitle: Text('Duration: ${template.durationDays} days', style: GoogleFonts.roboto()),
                  onTap: () => Navigator.of(context).pop(template),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }
}

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final previousRouteProvider = StateProvider<String?>((ref) => null);
