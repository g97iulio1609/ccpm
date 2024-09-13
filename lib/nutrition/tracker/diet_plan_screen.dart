import 'package:alphanessone/nutrition/models&Services/diet_plan_model.dart';
import 'package:alphanessone/nutrition/models&Services/diet_plan_services.dart';
import 'package:alphanessone/nutrition/models&Services/meals_model.dart';
import 'package:alphanessone/nutrition/models&Services/meals_services.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'meal_selection_dialog.dart';

class DietPlanScreen extends ConsumerStatefulWidget {
  const DietPlanScreen({super.key});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  DateTime _startDate = DateTime.now();
  int _durationDays = 7;
  List<DietPlanDay> _days = [];

  @override
  void initState() {
    super.initState();
    _initializeDays();
  }

  void _initializeDays() {
    _days = [];
    for (int i = 0; i < _durationDays; i++) {
      final currentDate = _startDate.add(Duration(days: i));
      final dayOfWeek = _getDayOfWeek(currentDate.weekday);
      _days.add(DietPlanDay(dayOfWeek: dayOfWeek, mealIds: []));
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  void _updateDurationDays(int newDuration) {
    setState(() {
      _durationDays = newDuration;
      _initializeDays();
    });
  }

  Future<void> _selectMeals(int dayIndex) async {
    final selectedMealIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => MealSelectionDialog(
        userId: ref.read(usersServiceProvider).getCurrentUserId(),
        initialSelectedMealIds: _days[dayIndex].mealIds,
      ),
    );

    if (selectedMealIds != null) {
      setState(() {
        _days[dayIndex] = _days[dayIndex].copyWith(mealIds: selectedMealIds);
      });
    }
  }

  Future<void> _saveDietPlan() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final dietPlan = DietPlan(
        userId: ref.read(usersServiceProvider).getCurrentUserId(),
        name: _name,
        startDate: _startDate,
        durationDays: _durationDays,
        days: _days,
      );

      final dietPlanService = ref.read(dietPlanServiceProvider);
      final dietPlanId = await dietPlanService.createDietPlan(dietPlan);

      // Recupera il piano dietetico appena creato con l'ID
      final createdDietPlan = dietPlan.copyWith(id: dietPlanId);

      // Applica il piano dietetico appena creato
      await dietPlanService.applyDietPlan(createdDietPlan);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet Plan Saved and Applied')),
      );

      Navigator.of(context).pop();
    }
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        _initializeDays();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealsService = ref.watch(mealsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Diet Plan', style: GoogleFonts.roboto()),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Diet Plan Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a diet plan name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!.trim();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start Date: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickStartDate,
                    child: Text('Select Date', style: GoogleFonts.roboto()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Duration (days)'),
                keyboardType: TextInputType.number,
                initialValue: _durationDays.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration in days';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number of days';
                  }
                  return null;
                },
                onSaved: (value) {
                  _durationDays = int.parse(value!);
                },
                onChanged: (value) {
                  if (int.tryParse(value) != null && int.parse(value) > 0) {
                    _updateDurationDays(int.parse(value));
                  }
                },
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _days.length,
                itemBuilder: (context, dayIndex) {
                  final day = _days[dayIndex];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile(
                      title: Text(
                        '${day.dayOfWeek} (${day.mealIds.length} Meals Selected)',
                        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: day.mealIds.length,
                          itemBuilder: (context, mealIndex) {
                            final mealId = day.mealIds[mealIndex];
                            return FutureBuilder<Meal?>(
                              future: mealsService.getMealById(ref.read(usersServiceProvider).getCurrentUserId(), mealId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const ListTile(
                                    title: Text('Loading...'),
                                  );
                                } else if (snapshot.hasError) {
                                  return const ListTile(
                                    title: Text('Error loading meal'),
                                  );
                                } else if (!snapshot.hasData || snapshot.data == null) {
                                  return const ListTile(
                                    title: Text('Meal not found'),
                                  );
                                } else {
                                  final meal = snapshot.data!;
                                  return ListTile(
                                    title: Text(meal.mealType, style: GoogleFonts.roboto(fontSize: 16)),
                                    subtitle: Text('Calories: ${meal.totalCalories} kcal', style: GoogleFonts.roboto()),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _days[dayIndex] = _days[dayIndex].copyWith(
                                            mealIds: List.from(_days[dayIndex].mealIds)..removeAt(mealIndex),
                                          );
                                        });
                                      },
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _selectMeals(dayIndex),
                            icon: const Icon(Icons.add),
                            label: Text('Select Meals', style: GoogleFonts.roboto()),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDietPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: Text('Save & Apply Diet Plan', style: GoogleFonts.roboto(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
