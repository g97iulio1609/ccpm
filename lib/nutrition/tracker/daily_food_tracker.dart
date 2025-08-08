import 'package:alphanessone/UI/components/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meals_services.dart';
import 'food_list.dart';
import '../models/meals_model.dart' as meals;
import '../../Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import '../../UI/app_bar_custom.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';

// Provider per gestire l'ID utente corrente
final currentUserIdProvider = Provider.autoDispose((ref) {
  final usersService = ref.read(usersServiceProvider);
  return usersService.getCurrentUserId();
});

// Provider per gestire l'ID utente attivo
final activeUserIdProvider = Provider.autoDispose((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final selectedUserId = ref.watch(selectedUserIdProvider);

  // Se non c'è un utente selezionato, usa l'utente corrente
  return selectedUserId ?? currentUserId;
});

// Provider per l'inizializzazione dei dati
final initializationProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
      final mealsService = ref.read(mealsServiceProvider);
      final currentDate = ref.read(selectedDateProvider);
      final tdeeService = ref.read(tdeeServiceProvider);

      // Esegui le operazioni di inizializzazione in parallelo
      await Future.wait([
        mealsService.createDailyStatsIfNotExist(userId, currentDate),
        mealsService.createMealsIfNotExist(userId, currentDate),
      ]);

      return tdeeService.getMostRecentNutritionData(userId);
    });

class DailyFoodTracker extends ConsumerStatefulWidget {
  const DailyFoodTracker({super.key});

  @override
  DailyFoodTrackerState createState() => DailyFoodTrackerState();
}

class DailyFoodTrackerState extends ConsumerState<DailyFoodTracker>
    with SingleTickerProviderStateMixin {
  int _targetCalories = 2000;
  double _targetCarbs = 0;
  double _targetProteins = 0;
  double _targetFats = 0;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    // Imposta l'utente corrente come default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = ref.read(currentUserIdProvider);
      ref.read(selectedUserIdProvider.notifier).state = currentUserId;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _userSearchController.dispose();
    _userSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(activeUserIdProvider);

    // Osserva il provider di inizializzazione
    final initializationState = ref.watch(initializationProvider(userId));

    return initializationState.when(
      data: (nutritionData) {
        if (nutritionData != null) {
          _targetCalories = (nutritionData['tdee'] ?? 2000).round();
          _targetCarbs = nutritionData['carbs'] ?? 0.0;
          _targetProteins = nutritionData['protein'] ?? 0.0;
          _targetFats = nutritionData['fat'] ?? 0.0;
        }

        return _buildMainContent(context);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Errore durante l\'inizializzazione: $error')),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final userId = ref.watch(activeUserIdProvider);
    final userAsyncValue = ref.watch(userProvider(userId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_shouldShowUserSelector())
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: AppCard(
                  background: colorScheme.surfaceContainerHighest.withAlpha(38),
                  child: UserTypeAheadField(
                    controller: _userSearchController,
                    focusNode: _userSearchFocusNode,
                    onSelected: (UserModel selectedUser) {
                      ref.read(selectedUserIdProvider.notifier).state =
                          selectedUser.id;
                      _userSearchController.text = selectedUser.name;
                    },
                    onChanged: (pattern) {
                      final allUsers = ref.read(userListProvider);
                      final filteredUsers = allUsers
                          .where(
                            (user) =>
                                user.name.toLowerCase().contains(
                                  pattern.toLowerCase(),
                                ) ||
                                user.email.toLowerCase().contains(
                                  pattern.toLowerCase(),
                                ),
                          )
                          .toList();
                      ref.read(filteredUserListProvider.notifier).state =
                          filteredUsers;
                    },
                  ),
                ),
              ),
            Expanded(
              child: _buildUserContent(
                userAsyncValue,
                selectedDate,
                userId,
                theme,
                colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserContent(
    AsyncValue<UserModel?> userAsyncValue,
    DateTime selectedDate,
    String userId,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return userAsyncValue.when(
      data: (user) {
        if (user == null) {
          return _buildErrorWidget(
            'Utente non trovato',
            Icons.person_off_outlined,
            theme,
            colorScheme,
          );
        }
        return Consumer(
          builder: (context, ref, child) {
            final dailyStatsAsyncValue = ref.watch(
              dailyStatsProvider(selectedDate),
            );
            return dailyStatsAsyncValue.when(
              data: (stats) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMacroSummary(stats),
                    ),
                  ),
                  SliverFillRemaining(
                    child: FoodList(
                      selectedDate: selectedDate,
                      userId: user.id,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildErrorWidget(
                'Errore nel caricamento: $err',
                Icons.error_outline,
                theme,
                colorScheme,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorWidget(
        'Errore nel caricamento',
        Icons.error_outline,
        theme,
        colorScheme,
      ),
    );
  }

  Widget _buildErrorWidget(
    String message,
    IconData icon,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colorScheme.error),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            message,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary(meals.DailyStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: AppCard(
        background: colorScheme.surfaceContainerHighest.withAlpha(38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCaloriesSummary(stats, theme, colorScheme),
            SizedBox(height: AppTheme.spacing.lg),
            _buildMacrosList(stats, theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesSummary(
    meals.DailyStats stats,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calorie Giornaliere',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.sm,
                vertical: AppTheme.spacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
              ),
              child: Text(
                '${(_targetCalories - stats.totalCalories).toStringAsFixed(0)} rimanenti',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.md),
        Row(
          children: [
            Text(
              stats.totalCalories.toStringAsFixed(0),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(width: AppTheme.spacing.xs),
            Text(
              '/ $_targetCalories kcal',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacrosList(
    meals.DailyStats stats,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildMacroItem(
          'Proteine',
          stats.totalProtein,
          _targetProteins,
          colorScheme.tertiary,
          theme,
        ),
        SizedBox(height: AppTheme.spacing.md),
        _buildMacroItem(
          'Carboidrati',
          stats.totalCarbs,
          _targetCarbs,
          colorScheme.secondary,
          theme,
        ),
        SizedBox(height: AppTheme.spacing.md),
        _buildMacroItem(
          'Grassi',
          stats.totalFat,
          _targetFats,
          colorScheme.error,
          theme,
        ),
      ],
    );
  }

  Widget _buildMacroItem(
    String title,
    double value,
    double target,
    Color color,
    ThemeData theme,
  ) {
    final percentage = (value / target).clamp(0.0, 1.0);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}g',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _shouldShowUserSelector() {
    final userRole = ref.watch(userRoleProvider);
    return userRole == 'admin' || userRole == 'coach';
  }
}

final dailyStatsProvider = StreamProvider.autoDispose
    .family<meals.DailyStats, DateTime>((ref, date) async* {
      final mealsService = ref.read(mealsServiceProvider);
      final selectedUserId = ref.watch(selectedUserIdProvider);

      if (selectedUserId == null) {
        yield* const Stream.empty();
        return;
      }

      await Future.wait([
        mealsService.createDailyStatsIfNotExist(selectedUserId, date),
        mealsService.createMealsIfNotExist(selectedUserId, date),
      ]);

      yield* mealsService.getDailyStatsByDateStream(selectedUserId, date);
    });
