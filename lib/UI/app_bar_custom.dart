// app_bar_custom.dart

import 'package:alphanessone/Viewer/providers/training_program_provider.dart';
import 'package:alphanessone/exerciseManager/exercises_manager.dart';
import 'package:alphanessone/ExerciseRecords/maxrmdashboard.dart';
import 'package:alphanessone/measurements/measurements.dart';
import 'package:alphanessone/nutrition/models/meals_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:alphanessone/nutrition/services/meals_services.dart';
import 'package:alphanessone/nutrition/models/diet_plan_model.dart';
import 'package:alphanessone/nutrition/services/diet_plan_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alphanessone/Store/in_app_purchase_services.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/snackbar.dart';

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
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
  final bool _syncing = false; // Stato di caricamento per sincronizzazione

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);
    _inAppPurchaseService = InAppPurchaseService();
    // Inizializzazione se necessario
  }

  String _getTitleForRoute(String currentPath) {
    if (currentPath.contains('/workout_details/')) {
      return ref.watch(currentWorkoutNameProvider);
    } else if (currentPath.contains('/week_details/')) {
      return ref.watch(currentWeekNameProvider);
    } else if (currentPath.contains('/maxrmdashboard/exercise_stats')) {
      return ref.watch(currentMaxRMExerciseNameProvider);
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
      case '/ai/chat':
        return 'AI Assistant';
      case '/settings/ai':
        return 'Impostazioni AI';
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

    final mealsService = ref.read(mealsServiceProvider.notifier);
    final userService = ref.read(usersServiceProvider);
    final userId = userService.getCurrentUserId();
    final selectedDate = ref.read(selectedDateProvider);

    if (value == 'save_as_favorite') {
      final favoriteName = await _showFavoriteNameDialog();
      if (favoriteName != null && mounted) {
        await mealsService.saveDayAsFavorite(
          userId,
          selectedDate,
          favoriteName: favoriteName,
        );
      }
    } else if (value == 'apply_favorite_day') {
      final favoriteDays = await mealsService.getFavoriteDays(userId);
      if (mounted) {
        final selectedFavorite = await showDialog<FavoriteDay>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Seleziona un giorno preferito'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: favoriteDays.length,
                itemBuilder: (context, index) {
                  final day = favoriteDays[index];
                  return ListTile(
                    title: Text(day.favoriteName),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(day.date)),
                    onTap: () => Navigator.of(context).pop(day),
                  );
                },
              ),
            ),
          ),
        );
        if (selectedFavorite != null && mounted) {
          await mealsService.applyFavoriteDayToCurrent(
            userId,
            selectedFavorite.id!,
            selectedDate,
          );
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
              onPressed: () =>
                  Navigator.of(dialogContext).pop(nameController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncProducts() async {
    _showSnackBar('Sincronizzazione prodotti in corso...');
    try {
      await _inAppPurchaseService.syncProducts();
      _showSnackBar('Prodotti sincronizzati con successo');
    } catch (e) {
      _showSnackBar(
        'Errore durante la sincronizzazione dei prodotti: ${e.toString()}',
      );
    }
  }

  Future<void> _initializeStore() async {
    _showSnackBar('Inizializzazione store in corso...');
    try {
      await _inAppPurchaseService.initialize();
      _showSnackBar('Store inizializzato con successo');
    } catch (e) {
      _showSnackBar(
        'Errore durante l\'inizializzazione dello store: ${e.toString()}',
      );
    }
  }

  void _showSnackBar(String message) {
    AppSnackbar.info(
      context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isBackButtonVisible = currentRoute.split('/').length > 2;
    final selectedDate = ref.watch(selectedDateProvider);
    final isAdmin = widget.userRole == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isBackButtonVisible
            ? _buildLeadingButtons(currentRoute)
            : null,
        title: _isDailyFoodTrackerRoute(currentRoute)
            ? _buildDateSelector(selectedDate)
            : _buildTitle(currentRoute),
        actions: _buildActions(currentRoute, isAdmin),
      ),
    );
  }

  Widget _buildTitle(String currentRoute) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _getTitleForRoute(currentRoute);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.sm,
            vertical: AppTheme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(77),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          ),
          child: Icon(
            _getIconForRoute(currentRoute),
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  IconData _getIconForRoute(String currentPath) {
    if (currentPath.contains('/exercise_details/')) return Icons.fitness_center;
    if (currentPath.contains('/workout_details/')) return Icons.schedule;
    if (currentPath.contains('/week_details/')) return Icons.calendar_today;

    switch (currentPath) {
      case '/programs_screen':
        return Icons.people;
      case '/user_programs':
        return Icons.fitness_center;
      case '/exercises_list':
        return Icons.list;
      case '/subscriptions':
        return Icons.card_membership;
      case '/maxrmdashboard':
        return Icons.trending_up;
      case '/user_profile':
        return Icons.person;
      case '/training_program':
        return Icons.edit;
      case '/users_dashboard':
        return Icons.group;
      case '/volume_dashboard':
        return Icons.bar_chart;
      case '/measurements':
        return Icons.straighten;
      case '/tdee':
        return Icons.local_fire_department;
      case '/macros_selector':
        return Icons.pie_chart;
      case '/training_gallery':
        return Icons.photo_library;
      case '/food_tracker':
        return Icons.restaurant_menu;
      default:
        return Icons.dashboard;
    }
  }

  Widget _buildDateSelector(DateTime selectedDate) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: colorScheme.onSurfaceVariant.withAlpha(128),
              size: 20,
            ),
            onPressed: () {
              ref
                  .read(selectedDateProvider.notifier)
                  .update((state) => state.subtract(const Duration(days: 1)));
            },
          ),
          Text(
            _formatDate(selectedDate),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withAlpha(128),
              size: 20,
            ),
            onPressed: () {
              ref
                  .read(selectedDateProvider.notifier)
                  .update((state) => state.add(const Duration(days: 1)));
            },
          ),
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant.withAlpha(128),
                  size: 20,
                ),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
            menuChildren: _buildDayMenuItems(context).map((e) {
              Icon? leading;
              Text? label;
              if (e is PopupMenuItem<String> && e.child is Row) {
                final row = e.child as Row;
                for (final w in row.children) {
                  if (w is Icon) leading = w;
                  if (w is Text) label = w;
                }
              }
              return MenuItemButton(
                onPressed: () {
                  if (e is PopupMenuItem<String>) {
                    _onDayMenuSelected(e.value as String);
                  }
                },
                leadingIcon: leading,
                child: label ?? const Text(''),
              );
            }).toList(),
          ),
        ],
      ),
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
              MeasurementsPage.showAddMeasurementDialog(context, userId);
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
        MenuAnchor(
          builder: (context, controller, child) => IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: () async {
                final templateDietPlan = await _selectTemplate(context);
                if (templateDietPlan != null) {
                  final newDietPlan = templateDietPlan.copyWith(
                    id: null,
                    startDate: DateTime.now(),
                  );
                  final dietPlanId = await ref
                      .read(dietPlanServiceProvider)
                      .createDietPlan(newDietPlan);
                  final createdDietPlan = newDietPlan.copyWith(id: dietPlanId);
                  await ref
                      .read(dietPlanServiceProvider)
                      .applyDietPlan(createdDietPlan);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Template Applied as New Diet Plan'),
                      ),
                    );
                  }
                }
              },
              leadingIcon: const Icon(Icons.assignment_add),
              child: const Text('Apply Template'),
            ),
          ],
        ),
      );
    }

    if (currentRoute == '/ai/chat') {
      actions.add(
        IconButton(
          onPressed: () => context.go('/settings/ai'),
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Impostazioni AI',
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
          onPressed: _syncing ? null : _initializeStore,
          tooltip: 'Refresh',
        ),
      );
    }

    return actions;
  }

  Future<DietPlan?> _selectTemplate(BuildContext context) async {
    final userService = ref.read(usersServiceProvider);
    final adminId = userService.getCurrentUserId();
    final templates = await ref
        .read(dietPlanServiceProvider)
        .getDietPlanTemplatesStream(adminId)
        .first;

    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No templates available')));
      }
      return null;
    }

    return showDialog<DietPlan>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Select a Template',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  title: Text(template.name, style: GoogleFonts.roboto()),
                  subtitle: Text(
                    'Duration: ${template.durationDays} days',
                    style: GoogleFonts.roboto(),
                  ),
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

  List<PopupMenuEntry<String>> _buildDayMenuItems(BuildContext context) {
    return [
      const PopupMenuItem(
        value: 'save_as_favorite',
        child: Row(
          children: [
            Icon(Icons.favorite_border),
            SizedBox(width: 8),
            Text('Salva come Giorno Preferito'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'apply_favorite_day',
        child: Row(
          children: [
            Icon(Icons.favorite),
            SizedBox(width: 8),
            Text('Applica Giorno Preferito'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'add_diet_plan',
        child: Row(
          children: [
            Icon(Icons.add_chart),
            SizedBox(width: 8),
            Text('Aggiungi Piano Dietetico'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'view_diet_plans',
        child: Row(
          children: [
            Icon(Icons.list_alt),
            SizedBox(width: 8),
            Text('Visualizza Piani Dietetici'),
          ],
        ),
      ),
    ];
  }
}

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final previousRouteProvider = StateProvider<String?>((ref) => null);
final currentMaxRMExerciseNameProvider = StateProvider<String>((ref) => '');
