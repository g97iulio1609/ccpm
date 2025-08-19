// app_bar_custom.dart

import 'package:alphanessone/Viewer/providers/training_program_provider.dart';
import 'package:alphanessone/Viewer/UI/workout_provider.dart' as workout_ui;
import 'package:alphanessone/exerciseManager/exercises_manager.dart';
import 'package:alphanessone/ExerciseRecords/maxrmdashboard.dart';
import 'package:alphanessone/measurements/measurements.dart';
import 'package:alphanessone/nutrition/models/meals_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
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
import 'package:alphanessone/Main/route_metadata.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';

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
    final meta = RouteMetadata.resolveByCurrentPath(currentPath);
    if (meta != null) return meta.title;
    if (currentPath.contains('/workout_details/')) {
      return ref.watch(workout_ui.currentWorkoutNameProvider);
    } else if (currentPath.contains('/week_details/')) {
      return ref.watch(currentWeekNameProvider);
    } else if (currentPath.contains('/maxrmdashboard/exercise_stats')) {
      return ref.watch(currentMaxRMExerciseNameProvider);
    }
    return 'Alphaness One';
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
        return AppDialog(
          title: const Text('Add User'),
          actions: [
            AppDialogHelpers.buildCancelButton(
              context: dialogContext,
              label: 'Cancel',
            ),
            AppDialogHelpers.buildActionButton(
              context: dialogContext,
              label: 'Add',
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
            ),
          ],
          child: Form(
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
          builder: (context) => AppDialog(
            title: const Text('Seleziona un giorno preferito'),
            child: SizedBox(
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
        return AppDialog(
          title: const Text('Save as Favorite', style: TextStyle(fontSize: 16)),
          actions: <Widget>[
            AppDialogHelpers.buildCancelButton(
              context: dialogContext,
              label: 'Cancel',
            ),
            AppDialogHelpers.buildActionButton(
              context: dialogContext,
              label: 'Save',
              onPressed: () =>
                  Navigator.of(dialogContext).pop(nameController.text),
            ),
          ],
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Favorite Name',
              hintText: 'Enter a name for this favorite day',
            ),
          ),
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
    final colorScheme =
        theme.colorScheme; // kept for future AppBar icon/text tints
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isBackButtonVisible = currentRoute.split('/').length > 2;
    final selectedDate = ref.watch(selectedDateProvider);
    final isAdmin = widget.userRole == 'admin';

    final applyGlassEverywhere = ref.watch(appBarGlassAllRoutesProvider);
    final isTopLevel =
        !_isBreadcrumbRoute(currentRoute) &&
        !_isDailyFoodTrackerRoute(currentRoute);
    final useGlass = applyGlassEverywhere || isTopLevel;

    final appBar = AppBar(
      centerTitle: true,
      backgroundColor: useGlass
          ? Colors.transparent
          : theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: colorScheme.onSurface,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      leading: isBackButtonVisible ? _buildLeadingButtons(currentRoute) : null,
      title: _isDailyFoodTrackerRoute(currentRoute)
          ? _buildDateSelector(selectedDate)
          : _isBreadcrumbRoute(currentRoute)
          ? _buildBreadcrumb(currentRoute)
          : _buildTitle(currentRoute),
      actions: _buildActions(currentRoute, isAdmin),
    );

    if (!useGlass) return appBar;

    return GlassLite(padding: EdgeInsets.zero, radius: 0, child: appBar);
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
        if (currentRoute.contains('/training_viewer/')) ...[
          // Breadcrumb: Week / Workout quando nel viewer
          Row(
            children: [
              Text(
                ref.watch(currentWeekNameProvider),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                ' / ',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                ref.watch(currentWorkoutNameProvider),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ] else ...[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIconForRoute(String currentPath) {
    final meta = RouteMetadata.resolveByCurrentPath(currentPath);
    if (meta != null) return meta.icon;
    if (currentPath.contains('/exercise_details/')) return Icons.fitness_center;
    if (currentPath.contains('/workout_details/')) return Icons.schedule;
    if (currentPath.contains('/week_details/')) return Icons.calendar_today;
    return Icons.dashboard;
  }

  bool _isBreadcrumbRoute(String currentRoute) {
    return currentRoute.contains('/user_programs') ||
        currentRoute.contains('/workout_details') ||
        currentRoute.contains('/week_details');
  }

  Widget _buildBreadcrumb(String currentRoute) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> crumbs = [];

    Widget chip(IconData icon, String text) => Container(
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
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          SizedBox(width: AppTheme.spacing.xs),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    // Root
    crumbs.add(chip(Icons.fitness_center, 'Allenamenti'));

    // Week name if available
    final weekName = ref.read(currentWeekNameProvider);
    if (weekName.isNotEmpty) {
      crumbs.add(_breadcrumbSeparator(colorScheme));
      crumbs.add(chip(Icons.calendar_today, weekName));
    }

    // Workout name if available
    final workoutName = ref.read(currentWorkoutNameProvider);
    if (workoutName.isNotEmpty) {
      crumbs.add(_breadcrumbSeparator(colorScheme));
      crumbs.add(chip(Icons.schedule, workoutName));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: crumbs),
    );
  }

  Widget _breadcrumbSeparator(ColorScheme colorScheme) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.xs),
    child: Icon(
      Icons.chevron_right,
      size: 18,
      color: colorScheme.onSurfaceVariant.withAlpha(128),
    ),
  );

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
          tooltip: 'Salva Programma',
          onPressed: () => widget.controller?.submitProgram(context),
          icon: const Icon(Icons.save_rounded),
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

    // Azioni coerenti nel viewer: salva completamenti e note
    if (currentRoute.contains('/training_viewer/')) {
      actions.addAll([
        IconButton(
          tooltip: 'Segna tutto completato',
          onPressed: () {
            // Il dettaglio del completamento batch vive nel Viewer; qui apriamo un bottom sheet dedicato
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.done_all_rounded),
                      title: const Text('Completa serie rimanenti'),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.note_alt_outlined),
                      title: const Text('Gestisci note esercizio'),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ]);
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
          scrollable: true,
          insetPadding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
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
