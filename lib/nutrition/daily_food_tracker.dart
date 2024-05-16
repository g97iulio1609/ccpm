import 'package:alphanessone/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'meals_services.dart';
import 'macros_services.dart';
import 'food_list.dart';
import 'food_management.dart';
import 'meals_model.dart' as meals;

class DailyFoodTracker extends ConsumerStatefulWidget {
  const DailyFoodTracker({super.key});

  @override
  _DailyFoodTrackerState createState() => _DailyFoodTrackerState();
}

class _DailyFoodTrackerState extends ConsumerState<DailyFoodTracker> {
  DateTime _selectedDate = DateTime.now();
  int _targetCalories = 2000;

  @override
  void initState() {
    super.initState();
    _loadUserTDEE();
  }

  Future<void> _loadUserTDEE() async {
    final userService = ref.read(usersServiceProvider);
    final userId = userService.getCurrentUserId();
    final tdeeData = await userService.getTDEEData(userId);
    if (tdeeData != null && tdeeData['tdee'] != null) {
      setState(() {
        _targetCalories = tdeeData['tdee'].round();
      });
    }
  }

  void _navigateToAddFood(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FoodManagement()),
    );
  }

  void _changeDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dailyStats = ref.watch(dailyStatsProvider(_selectedDate));

    final bool isToday = _selectedDate.isAtSameMomentAs(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            Text(
              isToday ? 'Today' : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              _changeDate(_selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _changeDate(_selectedDate.add(const Duration(days: 1)));
            },
          ),
        ],
      ),
      body: dailyStats.when(
        data: (stats) {
          return Column(
            children: [
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildMacroItem('Protein', stats.totalProtein, 210, Colors.green)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMacroItem('Carbohydrates', stats.totalCarbs, 125, Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMacroItem('Fat', stats.totalFat, 35, Colors.purple)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stats.totalCalories.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          '${(_targetCalories - stats.totalCalories).toStringAsFixed(0)} Cal Remaining',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'of $_targetCalories Cal Goal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FoodList(selectedDate: _selectedDate),
              ),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search for food',
                          hintStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search, color: Colors.white54),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (query) {
                          ref.read(macrosServiceProvider).searchFoods(query);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddFood(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildMacroItem(String title, double value, double target, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: LinearProgressIndicator(
            value: value / target,
            backgroundColor: Colors.white,
            color: color,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

final dailyStatsProvider = StreamProvider.autoDispose.family<meals.DailyStats, DateTime>((ref, date) {
  final mealsService = ref.read(mealsServiceProvider);
  final userService = ref.read(usersServiceProvider);
  final userId = userService.getCurrentUserId();

  return mealsService.getDailyStatsByDateStream(userId, date);
});
