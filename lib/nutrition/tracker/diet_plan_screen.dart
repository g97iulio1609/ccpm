// diet_plan_screen.dart

import 'package:alphanessone/nutrition/models/diet_plan_model.dart';
import 'package:alphanessone/nutrition/services/diet_plan_services.dart';
import 'package:alphanessone/nutrition/models/meals_model.dart';
import 'package:alphanessone/nutrition/services/meals_services.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'meal_selection_dialog.dart'; // Assicurati che questo dialog esista


class DietPlanScreen extends ConsumerStatefulWidget {
  final DietPlan? existingDietPlan; // Parametro opzionale per la modifica

  const DietPlanScreen({super.key, this.existingDietPlan});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late DateTime _startDate;
  late int _durationDays;
  late List<DietPlanDay> _days;

  @override
  void initState() {
    super.initState();
    if (widget.existingDietPlan != null) {
      // Modalità modifica
      _name = widget.existingDietPlan!.name;
      _startDate = widget.existingDietPlan!.startDate;
      _durationDays = widget.existingDietPlan!.durationDays;
      _days = List<DietPlanDay>.from(widget.existingDietPlan!.days);
    } else {
      // Modalità creazione
      _name = '';
      _startDate = DateTime.now();
      _durationDays = 7;
      _days = [];
      _initializeDays();
    }
  }

  /// Inizializza i giorni in base alla durata e alla data di inizio
  void _initializeDays() {
    final newDays = <DietPlanDay>[];
    for (int i = 0; i < _durationDays; i++) {
      final currentDate = _startDate.add(Duration(days: i));
      final dayOfWeek = _getDayOfWeek(currentDate.weekday);
      if (i < _days.length) {
        // Mantieni i mealIds esistenti
        newDays.add(_days[i].copyWith(dayOfWeek: dayOfWeek));
      } else {
        // Aggiungi nuovi giorni
        newDays.add(DietPlanDay(dayOfWeek: dayOfWeek, mealIds: []));
      }
    }
    // Se la nuova durata è minore della precedente, tronca la lista
    if (newDays.length > _durationDays) {
      _days = newDays.sublist(0, _durationDays);
    } else {
      _days = newDays;
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
    final userService = ref.read(usersServiceProvider);
    final selectedUserId = ref.read(selectedUserIdProvider);
    final userId = selectedUserId ?? userService.getCurrentUserId();

    final selectedMealIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => MealSelectionDialog(
        userId: userId,
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

      final dietPlanService = ref.read(dietPlanServiceProvider);
      final userService = ref.read(usersServiceProvider);
      final currentUserId = userService.getCurrentUserId();
      final currentUserRole = userService.getCurrentUserRole();
      final selectedUserId = ref.read(selectedUserIdProvider);
      final userId = selectedUserId ?? currentUserId;

      if (widget.existingDietPlan != null) {
        // Modalità modifica
        final updatedDietPlan = widget.existingDietPlan!.copyWith(
          name: _name,
          startDate: _startDate,
          durationDays: _durationDays,
          days: _days,
        );

        await dietPlanService.updateDietPlan(updatedDietPlan);
        await dietPlanService.applyDietPlan(updatedDietPlan);

        // Se l'utente corrente è admin o coach, salva come template
        if (currentUserRole == 'admin' || currentUserRole == 'coach') {
          final templateDietPlan = updatedDietPlan.copyWith(
            id: null, // Firestore genererà un nuovo ID
          );
          await dietPlanService.createDietPlanTemplate(currentUserId, templateDietPlan);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diet Plan Updated and Applied')),
          );
        }
      } else {
        // Modalità creazione
        final newDietPlan = DietPlan(
          userId: userId,
          name: _name,
          startDate: _startDate,
          durationDays: _durationDays,
          days: _days,
        );

        final dietPlanId = await dietPlanService.createDietPlan(newDietPlan);
        final createdDietPlan = newDietPlan.copyWith(id: dietPlanId);

        await dietPlanService.applyDietPlan(createdDietPlan);

        // Se l'utente corrente è admin o coach, salva come template
        if (currentUserRole == 'admin' || currentUserRole == 'coach') {
          final templateDietPlan = createdDietPlan.copyWith(
            id: null, // Firestore genererà un nuovo ID
          );
          await dietPlanService.createDietPlanTemplate(currentUserId, templateDietPlan);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diet Plan Saved and Applied')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Torna indietro alla schermata precedente
      }
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
    final isEditing = widget.existingDietPlan != null;

    final userService = ref.watch(usersServiceProvider);
    final selectedUserId = ref.watch(selectedUserIdProvider);
    final userId = selectedUserId ?? userService.getCurrentUserId();

    return Scaffold(
     
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nome del piano dietetico
              TextFormField(
                initialValue: _name,
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

              // Data di inizio
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

              // Durata in giorni
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

              // Lista dei giorni
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
                        // Lista dei pasti per il giorno
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: day.mealIds.length,
                          itemBuilder: (context, mealIndex) {
                            final mealId = day.mealIds[mealIndex];
                            return FutureBuilder<Meal?>(
                              future: mealsService.getMealById(userId, mealId), // Usa l'userId corretto
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

                        // Bottone per selezionare nuovi pasti
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

              // Bottone di salvataggio
              ElevatedButton(
                onPressed: _saveDietPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: Text(
                  isEditing ? 'Update & Apply Diet Plan' : 'Save & Apply Diet Plan',
                  style: GoogleFonts.roboto(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
