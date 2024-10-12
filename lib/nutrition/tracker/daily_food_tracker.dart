import 'package:alphanessone/UI/appBar_custom.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meals_services.dart';
import 'food_list.dart';
import '../models/meals_model.dart' as meals;
import 'package:google_fonts/google_fonts.dart';

class DailyFoodTracker extends ConsumerStatefulWidget {
  const DailyFoodTracker({super.key});

  @override
  DailyFoodTrackerState createState() => DailyFoodTrackerState();
}

class DailyFoodTrackerState extends ConsumerState<DailyFoodTracker> {
  int _targetCalories = 2000;
  double _targetCarbs = 0;
  double _targetProteins = 0;
  double _targetFats = 0;

  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
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
    });
  }

  @override
  void dispose() {
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
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedUserId = ref.watch(selectedUserIdProvider);
    final userId = selectedUserId ?? ref.read(usersServiceProvider).getCurrentUserId();
    final userAsyncValue = ref.watch(userProvider(userId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_shouldShowUserSelector())
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: UserTypeAheadField(
                  controller: _userSearchController,
                  focusNode: _userSearchFocusNode,
                  onSelected: (UserModel selectedUser) async {
                    ref.read(selectedUserIdProvider.notifier).state = selectedUser.id;
                    _userSearchController.text = selectedUser.name;
                    await _initializeData(selectedUser.id);
                    await _loadUserTDEEAndMacros(selectedUser.id);
                  },
                  onChanged: (pattern) {
                    final allUsers = ref.read(userListProvider);
                    final filteredUsers = allUsers.where((user) =>
                      user.name.toLowerCase().contains(pattern.toLowerCase()) ||
                      user.email.toLowerCase().contains(pattern.toLowerCase())
                    ).toList();
                    ref.read(filteredUserListProvider.notifier).state = filteredUsers;
                  },
                ),
              ),
            userAsyncValue.when(
              data: (user) {
                if (user == null) {
                  return const Expanded(
                    child: Center(child: Text('User not found')),
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
                              child: _buildMacroSummary(stats),
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
                          child: Center(child: CircularProgressIndicator())),
                      error: (err, stack) => Expanded(
                          child: Center(child: Text('Error: $err'))),
                    );
                  },
                );
              },
              loading: () => const Expanded(
                  child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => Expanded(
                  child: Center(child: Text('Error: $err'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSummary(meals.DailyStats stats) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: _buildMacroItem(
                      'Protein', stats.totalProtein, _targetProteins,
                      Theme.of(context).colorScheme.tertiary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMacroItem(
                      'Carbohydrates', stats.totalCarbs, _targetCarbs,
                      Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMacroItem(
                      'Fat', stats.totalFat, _targetFats,
                      Theme.of(context).colorScheme.error)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stats.totalCalories.toStringAsFixed(0),
                style: GoogleFonts.roboto(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                ),
              ),
              Text(
                '${(_targetCalories - stats.totalCalories).toStringAsFixed(0)} Cal Remaining',
                style: GoogleFonts.roboto(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            'of $_targetCalories Cal Goal',
            style: GoogleFonts.roboto(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowUserSelector() {
    final userRole = ref.watch(userRoleProvider);
    return userRole == 'admin' || userRole == 'coach';
  }

  Widget _buildMacroItem(String title, double value, double target, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: LinearProgressIndicator(
            value: (value / target).clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: color,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
          style: GoogleFonts.roboto(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

final dailyStatsProvider = StreamProvider.autoDispose.family<meals.DailyStats, DateTime>((ref, date) async* {
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