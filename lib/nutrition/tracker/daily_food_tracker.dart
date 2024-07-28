import 'package:alphanessone/UI/appBar_custom.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models&Services/meals_services.dart';
import 'food_list.dart';
import '../models&Services/meals_model.dart' as meals;
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
  UserModel? _selectedUser;
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserTDEEAndMacros();
    _initializeUserData();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    final userService = ref.read(usersServiceProvider);
    final userId = _selectedUser?.id ?? userService.getCurrentUserId();
    await _initializeData(userId);
  }

  Future<void> _initializeData(String userId) async {
    final mealsService = ref.read(mealsServiceProvider);
    final currentDate = ref.read(selectedDateProvider);
    
    await mealsService.createDailyStatsIfNotExist(userId, currentDate);
    await mealsService.createMealsIfNotExist(userId, currentDate);
  }

  Future<void> _loadUserTDEEAndMacros() async {
    final userService = ref.read(usersServiceProvider);
    final userId = _selectedUser?.id ?? userService.getCurrentUserId();
    
    final tdeeService = ref.read(tdeeServiceProvider);
    
    final tdeeData = await tdeeService.getTDEEData(userId);
    final macrosData = await tdeeService.getUserMacros(userId);

    if (tdeeData != null && tdeeData['tdee'] != null) {
      setState(() {
        _targetCalories = tdeeData['tdee'].round();
      });
    }

    setState(() {
      _targetCarbs = macrosData['carbs']!;
      _targetProteins = macrosData['protein']!;
      _targetFats = macrosData['fat']!;
    });
  }

   @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyStats = ref.watch(dailyStatsProvider(selectedDate));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_shouldShowUserSelector()) 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildUserSelector(),
              ),
            dailyStats.when(
              data: (stats) => Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildMacroSummary(stats),
                    ),
                    SliverFillRemaining(
                      child: FoodList(
                        selectedDate: selectedDate,
                        userId: _selectedUser?.id ?? ref.read(usersServiceProvider).getCurrentUserId(),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
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
              Expanded(child: _buildMacroItem('Protein', stats.totalProtein, _targetProteins, Theme.of(context).colorScheme.tertiary)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroItem('Carbohydrates', stats.totalCarbs, _targetCarbs, Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroItem('Fat', stats.totalFat, _targetFats, Theme.of(context).colorScheme.error)),
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
    final userService = ref.read(usersServiceProvider);
    final currentUserRole = userService.getCurrentUserRole();
    return currentUserRole == 'admin' || currentUserRole == 'coach';
  }

  Widget _buildUserSelector() {
    return UserTypeAheadField(
      controller: _userSearchController,
      focusNode: FocusNode(),
      onSelected: (user) async {
        setState(() {
          _selectedUser = user;
          _userSearchController.text = user.name;
        });
        await _initializeData(user.id);
        await _loadUserTDEEAndMacros();
      },
      onChanged: (value) {},
    );
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
  final userService = ref.read(usersServiceProvider);
  final userId = userService.getCurrentUserId();

  await mealsService.createDailyStatsIfNotExist(userId, date);
  await mealsService.createMealsIfNotExist(userId, date);
  yield* mealsService.getDailyStatsByDateStream(userId, date);
});