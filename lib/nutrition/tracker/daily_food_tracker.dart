import 'package:alphanessone/UI/components/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meals_services.dart';
import 'food_list.dart';
import '../models/meals_model.dart' as meals;
import '../../Main/app_theme.dart';
import '../../UI/appBar_custom.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';

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
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userRole = ref.read(userRoleProvider);
      final currentUserId = ref.read(usersServiceProvider).getCurrentUserId();

      if (userRole == 'admin' || userRole == 'coach') {
        if (ref.read(selectedUserIdProvider) == null) {
          ref.read(selectedUserIdProvider.notifier).state = currentUserId;
        }
      } else if (userRole == 'client' || userRole == 'client_premium') {
        ref.read(selectedUserIdProvider.notifier).state = currentUserId;
      }

      await _initializeUserData();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _userSearchController.dispose();
    _userSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    final userId = ref.read(selectedUserIdProvider) ??
        ref.read(usersServiceProvider).getCurrentUserId();
    await _initializeData(userId);
    await _loadUserTDEEAndMacros(userId);
  }

  Future<void> _initializeData(String userId) async {
    final mealsService = ref.read(mealsServiceProvider);
    final currentDate = ref.read(selectedDateProvider);

    await mealsService.createDailyStatsIfNotExist(userId, currentDate);
    await mealsService.createMealsIfNotExist(userId, currentDate);
  }

  Future<void> _loadUserTDEEAndMacros(String userId) async {
    final tdeeService = ref.read(tdeeServiceProvider);
    final nutritionData = await tdeeService.getMostRecentNutritionData(userId);

    if (nutritionData != null) {
      setState(() {
        _targetCalories = (nutritionData['tdee'] ?? 2000).round();
        _targetCarbs = nutritionData['carbs'] ?? 0.0;
        _targetProteins = nutritionData['protein'] ?? 0.0;
        _targetFats = nutritionData['fat'] ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedUserId = ref.watch(selectedUserIdProvider);
    final userId =
        selectedUserId ?? ref.read(usersServiceProvider).getCurrentUserId();
    final userAsyncValue = ref.watch(userProvider(userId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_shouldShowUserSelector())
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    boxShadow: AppTheme.elevations.small,
                  ),
                  child: UserTypeAheadField(
                    controller: _userSearchController,
                    focusNode: _userSearchFocusNode,
                    onSelected: (UserModel selectedUser) async {
                      ref.read(selectedUserIdProvider.notifier).state =
                          selectedUser.id;
                      _userSearchController.text = selectedUser.name;
                      await _initializeData(selectedUser.id);
                      await _loadUserTDEEAndMacros(selectedUser.id);
                    },
                    onChanged: (pattern) {
                      final allUsers = ref.read(userListProvider);
                      final filteredUsers = allUsers
                          .where((user) =>
                              user.name
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()) ||
                              user.email
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                          .toList();
                      ref.read(filteredUserListProvider.notifier).state =
                          filteredUsers;
                    },
                  ),
                ),
              ),
            userAsyncValue.when(
              data: (user) {
                if (user == null) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 48,
                            color: colorScheme.error,
                          ),
                          SizedBox(height: AppTheme.spacing.md),
                          Text(
                            'Utente non trovato',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Consumer(
                  builder: (context, ref, child) {
                    final dailyStatsAsyncValue =
                        ref.watch(dailyStatsProvider(selectedDate));
                    return dailyStatsAsyncValue.when(
                      data: (stats) => Expanded(
                        child: CustomScrollView(
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
                      ),
                      loading: () => const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: colorScheme.error,
                              ),
                              SizedBox(height: AppTheme.spacing.md),
                              Text(
                                'Errore nel caricamento',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacing.sm),
                              Text(
                                err.toString(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      SizedBox(height: AppTheme.spacing.md),
                      Text(
                        'Errore nel caricamento',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSummary(meals.DailyStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.lg),
        child: Column(
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
            SizedBox(height: AppTheme.spacing.lg),
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
        ),
      ),
    );
  }

  Widget _buildMacroItem(
      String title, double value, double target, Color color, ThemeData theme) {
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
            color: color.withOpacity(0.2),
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

  await mealsService.createDailyStatsIfNotExist(selectedUserId, date);
  await mealsService.createMealsIfNotExist(selectedUserId, date);

  yield* mealsService.getDailyStatsByDateStream(selectedUserId, date);
});
