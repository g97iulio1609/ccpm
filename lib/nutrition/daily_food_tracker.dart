import 'package:alphanessone/users_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_model.dart';
import 'macros_services.dart';
import 'food_management.dart';
import 'food_list.dart';

class DailyFoodTracker extends ConsumerStatefulWidget {
  const DailyFoodTracker({super.key});

  @override
  _DailyFoodTrackerState createState() => _DailyFoodTrackerState();
}

class _DailyFoodTrackerState extends ConsumerState<DailyFoodTracker> {
  DateTime _selectedDate = DateTime.now();
  int _targetCalories = 2000;
  double _consumedCalories = 1425;

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

  @override
  Widget build(BuildContext context) {
    final macrosService = ref.watch(macrosServiceProvider);
    final userService = ref.watch(usersServiceProvider);
    final userId = userService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Row(
          children: [
            Icon(Icons.calendar_today),
            SizedBox(width: 8),
            Text('Today'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
      body: Column(
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
                    Expanded(child: _buildMacroItem('Protein', 105, 210, Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMacroItem('Carbohydrates', 95, 125, Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMacroItem('Fat', 15, 35, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _consumedCalories.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      '${(_targetCalories - _consumedCalories).toStringAsFixed(0)} Cal Remaining',
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
                      macrosService.searchFoods(query);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
